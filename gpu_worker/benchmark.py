"""Kaggle CLI: prepare a consented image manifest, then benchmark both models.

This is a shared-preprocessing engineering comparison, not a paper reproduction.
Run models in separate processes/environments; see notebooks and README.
"""
import argparse
import csv
import json
import os
from pathlib import Path
import sys
import time


def prepare(manifest, output):
    import numpy as np
    import torch
    from PIL import Image, ImageOps
    import catvton_pipeline as cat
    cat.get_pipeline()
    from utils import resize_and_padding
    from densepose.vis.densepose_results import DensePoseResultsFineSegmentationVisualizer
    from densepose.vis.extractor import create_extractor
    output.mkdir(parents=True, exist_ok=True)
    prepared = []
    for index, case in enumerate(json.loads(manifest.read_text())):
        started = time.perf_counter()
        folder = output / str(index); folder.mkdir(exist_ok=True)
        person = resize_and_padding(ImageOps.exif_transpose(Image.open(manifest.parent / case['person'])).convert('RGB'), (768,1024))
        cloth = resize_and_padding(ImageOps.exif_transpose(Image.open(manifest.parent / case['garment'])).convert('RGB'), (768,1024))
        with torch.inference_mode():
            mask = cat._masker(person, cat.REGIONS[case['category']])['mask']
            if mask.getbbox() is None:
                raise ValueError(f"No clothing region detected for case {index}")
            # IDM expects a coloured DensePose segmentation, not CatVTON's
            # raw integer-label mask. Use the official visualizer on black.
            bgr = np.asarray(person.resize((384,512)))[:, :, ::-1].copy()
            instances = cat._masker.densepose_processor.predictor(bgr)['instances']
            vis = DensePoseResultsFineSegmentationVisualizer(alpha=1.0)
            pose = vis.visualize(np.zeros_like(bgr), create_extractor(vis)(instances))
            pose = Image.fromarray(pose[:, :, ::-1]).resize((768,1024))
        for name, image in [('person',person),('garment',cloth),('mask',mask),('pose',pose)]:
            image.save(folder / f'{name}.png')
        prepared.append({**case, **{name: str((folder / f'{name}.png').resolve()) for name in ['person','garment','mask','pose']},
                         'case_id': index, 'preprocessing_seconds': time.perf_counter()-started})
    (output / 'prepared.json').write_text(json.dumps(prepared, indent=2))


def load_idm():
    import torch
    sys.path.insert(0, os.environ['IDMVTON_DIR'])
    from src.tryon_pipeline import StableDiffusionXLInpaintPipeline
    from src.unet_hacked_tryon import UNet2DConditionModel
    from src.unet_hacked_garmnet import UNet2DConditionModel as GarmentUNet
    from transformers import CLIPVisionModelWithProjection
    model = 'yisol/IDM-VTON'
    pipeline = StableDiffusionXLInpaintPipeline.from_pretrained(model,
        unet=UNet2DConditionModel.from_pretrained(model, subfolder='unet', torch_dtype=torch.float16),
        image_encoder=CLIPVisionModelWithProjection.from_pretrained(model, subfolder='image_encoder', torch_dtype=torch.float16),
        torch_dtype=torch.float16)
    pipeline.unet_encoder = GarmentUNet.from_pretrained(model, subfolder='unet_encoder', torch_dtype=torch.float16).to('cuda')
    pipeline.unet_encoder.requires_grad_(False)
    pipeline.enable_model_cpu_offload()
    pipeline.enable_vae_slicing()
    return pipeline


def run_idm(pipeline, case, steps, seed):
    import torch
    from PIL import Image
    from torchvision import transforms
    transform = transforms.Compose([transforms.ToTensor(), transforms.Normalize([0.5], [0.5])])
    garment = Image.open(case['garment']).convert('RGB')
    description = case.get('description', case['category'])
    negative = 'monochrome, lowres, bad anatomy, worst quality, low quality'
    with torch.inference_mode():
        prompt, neg, pooled, neg_pooled = pipeline.encode_prompt('model is wearing ' + description,
            num_images_per_prompt=1, do_classifier_free_guidance=True, negative_prompt=negative)
        cloth_prompt, _, _, _ = pipeline.encode_prompt('a photo of ' + description,
            num_images_per_prompt=1, do_classifier_free_guidance=False)
        return pipeline(prompt_embeds=prompt.to('cuda',torch.float16), negative_prompt_embeds=neg.to('cuda',torch.float16),
            pooled_prompt_embeds=pooled.to('cuda',torch.float16), negative_pooled_prompt_embeds=neg_pooled.to('cuda',torch.float16),
            num_inference_steps=steps, generator=torch.Generator('cuda').manual_seed(seed), strength=1.0,
            pose_img=transform(Image.open(case['pose']).convert('RGB')).unsqueeze(0).to('cuda',torch.float16),
            text_embeds_cloth=cloth_prompt.to('cuda',torch.float16), cloth=transform(garment).unsqueeze(0).to('cuda',torch.float16),
            mask_image=Image.open(case['mask']).convert('L'), image=Image.open(case['person']).convert('RGB'),
            height=1024, width=768, ip_adapter_image=garment, guidance_scale=2.0)[0][0]


def benchmark(model, manifest, output, steps, seed):
    import torch
    from PIL import Image
    output.mkdir(parents=True, exist_ok=True)
    start = time.perf_counter()
    if model == 'catvton':
        import catvton_pipeline as cat
        pipeline = cat.get_pipeline()
    else:
        pipeline = load_idm()
    torch.cuda.synchronize()
    load_seconds = time.perf_counter() - start
    fields = ['model','case_id','category','seed','steps','load_seconds','preprocessing_seconds','seconds',
              'peak_vram_gib','result','error','identity_1_to_5','garment_fidelity_1_to_5','hem_sleeves_1_to_5','artifacts_1_to_5','notes']
    with (output / f'{model}.csv').open('w',newline='') as f:
        writer = csv.DictWriter(f,fieldnames=fields); writer.writeheader()
        for case in json.loads(manifest.read_text()):
            record = dict(model=model,case_id=case['case_id'],category=case['category'],seed=seed,steps=steps,
                          load_seconds=load_seconds,preprocessing_seconds=case['preprocessing_seconds'])
            torch.cuda.reset_peak_memory_stats(); start = time.perf_counter()
            try:
                if model == 'catvton':
                    from diffusers.image_processor import VaeImageProcessor
                    mask = VaeImageProcessor(vae_scale_factor=8,do_normalize=False,do_binarize=True,do_convert_grayscale=True).blur(Image.open(case['mask']).convert('L'),blur_factor=9)
                    with torch.inference_mode():
                        image = pipeline(image=Image.open(case['person']).convert('RGB'), condition_image=Image.open(case['garment']).convert('RGB'),
                            mask=mask,num_inference_steps=steps,guidance_scale=2.5,generator=torch.Generator('cuda').manual_seed(seed))[0]
                else:
                    image = run_idm(pipeline,case,steps,seed)
                torch.cuda.synchronize()
                path = output / f"{model}-{case['case_id']}.jpg"; image.save(path,quality=95)
                record['result'] = str(path)
            except Exception as exc:
                record['error'] = f'{type(exc).__name__}: {exc}'
                torch.cuda.empty_cache()
            record.update(seconds=time.perf_counter()-start,peak_vram_gib=torch.cuda.max_memory_allocated()/1024**3)
            writer.writerow(record); f.flush()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action',choices=['prepare','catvton','idm'])
    parser.add_argument('manifest',type=Path)
    parser.add_argument('output',type=Path)
    parser.add_argument('--steps',type=int,default=50)
    parser.add_argument('--seed',type=int,default=42)
    args = parser.parse_args()
    if args.action == 'prepare': prepare(args.manifest,args.output)
    else: benchmark(args.action,args.manifest,args.output,args.steps,args.seed)
