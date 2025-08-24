from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class PostBase(BaseModel):
    content: str
    image_url: Optional[str] = None

class PostCreate(PostBase):
    pass

class Post(PostBase):
    id: str
    user_id: str
    likes_count: int = 0
    comments_count: int = 0
    created_at: datetime
    updated_at: datetime
    
    class Config:
        from_attributes = True

class CommentBase(BaseModel):
    content: str

class CommentCreate(CommentBase):
    pass

class Comment(CommentBase):
    id: str
    post_id: str
    user_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True

class Like(BaseModel):
    id: str
    post_id: str
    user_id: str
    created_at: datetime
    
    class Config:
        from_attributes = True
```

```

