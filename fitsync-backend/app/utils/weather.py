import requests
from typing import Dict, List, Optional
from app.config import settings

class WeatherService:
    def __init__(self):
        self.api_key = settings.weather_api_key
        self.base_url = "http://api.openweathermap.org/data/2.5"
    
    async def get_weather_recommendations(self, lat: float, lon: float) -> Dict:
        """Get weather-based clothing recommendations"""
        try:
            weather_data = await self._fetch_weather(lat, lon)
            recommendations = self._generate_weather_recommendations(weather_data)
            return recommendations
        except Exception as e:
            return {'error': str(e)}
    
    async def _fetch_weather(self, lat: float, lon: float) -> Dict:
        """Fetch current weather and forecast"""
        # Current weather
        current_url = f"{self.base_url}/weather"
        current_params = {
            'lat': lat,
            'lon': lon,
            'appid': self.api_key,
            'units': 'metric'
        }
        
        current_response = requests.get(current_url, params=current_params)
        current_data = current_response.json()
        
        # 5-day forecast
        forecast_url = f"{self.base_url}/forecast"
        forecast_response = requests.get(forecast_url, params=current_params)
        forecast_data = forecast_response.json()
        
        return {
            'current': current_data,
            'forecast': forecast_data
        }
    
    def _generate_weather_recommendations(self, weather_data: Dict) -> Dict:
        """Generate clothing recommendations based on weather"""
        current = weather_data['current']
        temp = current['main']['temp']
        humidity = current['main']['humidity']
        weather_condition = current['weather'][0]['main'].lower()
        
        recommendations = {
            'temperature_advice': self._temperature_advice(temp),
            'weather_advice': self._weather_condition_advice(weather_condition),
            'humidity_advice': self._humidity_advice(humidity),
            'suggested_items': self._suggest_items(temp, weather_condition, humidity)
        }
        
        return recommendations
    
    def _temperature_advice(self, temp: float) -> str:
        """Temperature-based advice"""
        if temp < 0:
            return "Very cold - layer up with thermal wear, heavy coat, winter accessories"
        elif temp < 10:
            return "Cold - sweater or jacket required, long pants recommended"
        elif temp < 20:
            return "Cool - light jacket or cardigan, comfortable layers"
        elif temp < 30:
            return "Warm - light fabrics, short sleeves, breathable materials"
        else:
            return "Hot - minimal clothing, very light and breathable fabrics"
    
    def _weather_condition_advice(self, condition: str) -> str:
        """Weather condition specific advice"""
        advice_map = {
            'rain': "Waterproof jacket, umbrella, water-resistant shoes",
            'snow': "Warm boots, waterproof outerwear, thermal layers",
            'clear': "Sun protection if needed, comfortable regular wear",
            'clouds': "Regular wear, light jacket for comfort",
            'thunderstorm': "Stay indoors or waterproof everything"
        }
        return advice_map.get(condition, "Check weather conditions and dress appropriately")
    
    def _humidity_advice(self, humidity: float) -> str:
        """Humidity-based advice"""
        if humidity > 80:
            return "High humidity - breathable, moisture-wicking fabrics"
        elif humidity < 30:
            return "Low humidity - avoid static-prone materials, moisturize"
        else:
            return "Comfortable humidity levels"
    
    def _suggest_items(self, temp: float, condition: str, humidity: float) -> List[str]:
        """Suggest specific clothing items"""
        items = []
        
        # Temperature-based items
        if temp < 10:
            items.extend(['jacket', 'long_pants', 'closed_shoes', 'sweater'])
        elif temp < 25:
            items.extend(['light_jacket', 'long_pants', 'shirt'])
        else:
            items.extend(['t_shirt', 'shorts', 'sandals', 'light_dress'])
        
        # Weather condition items
        if condition == 'rain':
            items.extend(['raincoat', 'waterproof_shoes', 'umbrella'])
        elif condition == 'snow':
            items.extend(['winter_coat', 'boots', 'gloves', 'hat'])
        
        # Humidity considerations
        if humidity > 70:
            items.extend(['breathable_fabric', 'moisture_wicking'])
        
        return list(set(items))  # Remove duplicates