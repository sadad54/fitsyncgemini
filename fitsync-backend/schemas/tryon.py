class TryOnRequest(BaseModel):
    user_photo_url: str = Field(..., description="URL of user photo")
    outfit_items: List[str] = Field(..., description="List of outfit item IDs")
    pose_adjustment: bool = Field(True, description="Enable pose adjustment")
    lighting_adjustment: bool = Field(True, description="Enable lighting adjustment")
    background_removal: bool = Field(False, description="Remove original background")
    style_transfer: bool = Field(False, description="Apply style transfer")

class TryOnResult(BaseModel):
    job_id: str = Field(..., description="Job identifier")
    status: str = Field(..., description="Job status (processing, completed, failed)")
    result_url: Optional[str] = Field(None, description="URL of generated image")
    thumbnail_url: Optional[str] = Field(None, description="URL of thumbnail")
    processing_time_seconds: Optional[float] = Field(None, description="Processing time")
    quality_score: Optional[float] = Field(None, ge=0, le=1, description="Result quality score")
    recommendations: Optional[List[str]] = Field(None, description="Improvement suggestions")
    created_at: datetime = Field(default_factory=datetime.utcnow)
    expires_at: Optional[datetime] = Field(None, description="Result expiration time")