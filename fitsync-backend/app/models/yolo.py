from ultralytics import YOLO

model = YOLO("yolov8n.pt")  # Pre-trained YOLO model

def detect_clothing(image_path: str):
    results = model(image_path)
    boxes = results[0].boxes
    classes = boxes.cls.tolist()
    names = results[0].names

    detected_items = [names[int(cls)] for cls in classes]
    return detected_items
