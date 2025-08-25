import asyncio
from typing import Dict, List


class GoogleTrendsClient:
    async def get_trending_searches(self, keywords: List[str], timeframe: str, geo: str) -> Dict:
        # Minimal stub returning mock data to unblock server startup
        await asyncio.sleep(0)
        trends = [
            {"title": kw, "value": 50 + i * 5, "growth": 10 + i * 2}
            for i, kw in enumerate(keywords)
        ]
        return {"success": True, "trends": trends}

    async def get_trend_over_time(self, keyword: str, timeframe: str) -> Dict:
        await asyncio.sleep(0)
        data = [{"date": f"2024-0{m}-01", "value": 20 + m * 3} for m in range(1, 7)]
        return {"success": True, "data": data}


