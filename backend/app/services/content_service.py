import re
import requests
import json
from typing import Optional, Dict, Tuple
from urllib.parse import urlparse, parse_qs
from datetime import datetime

class ContentMetadataService:
    """Service untuk fetch metadata dari platform eksternal"""
    
    # YouTube API Key (configure in settings)
    YOUTUBE_API_KEY = None
    
    @staticmethod
    def set_youtube_api_key(api_key: str):
        """Set YouTube API key"""
        ContentMetadataService.YOUTUBE_API_KEY = api_key
    
    @staticmethod
    def extract_youtube_video_id(url: str) -> Optional[str]:
        """Extract YouTube video ID dari berbagai format URL"""
        patterns = [
            # Standard formats
            r'(?:https?://)?(?:www\.)?youtube\.com/watch\?v=([a-zA-Z0-9_-]+)',
            r'(?:https?://)?youtu\.be/([a-zA-Z0-9_-]+)',
            r'(?:https?://)?(?:www\.)?youtube\.com/embed/([a-zA-Z0-9_-]+)',
            r'(?:https?://)?(?:www\.)?youtube\.com/v/([a-zA-Z0-9_-]+)',
            
            # Shorts format
            r'(?:https?://)?(?:www\.)?youtube\.com/shorts/([a-zA-Z0-9_-]+)',
            
            # With additional parameters
            r'(?:https?://)?(?:www\.)?youtube\.com/watch\?.*v=([a-zA-Z0-9_-]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        return None
    
    @staticmethod
    def extract_spotify_id(url: str) -> Optional[Tuple[str, str]]:
        """Extract Spotify type dan ID"""
        patterns = [
            r'(?:https?://)?open\.spotify\.com/(track|episode|playlist|album|show)/([a-zA-Z0-9]+)',
            r'(?:https?://)?spoti\.fi/([a-zA-Z0-9]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1), match.group(2)  # type, id
        return None
    
    @staticmethod
    def extract_vimeo_id(url: str) -> Optional[str]:
        """Extract Vimeo video ID"""
        patterns = [
            r'(?:https?://)?(?:www\.)?vimeo\.com/([0-9]+)',
            r'(?:https?://)?(?:www\.)?vimeo\.com/embed/([0-9]+)',
            r'(?:https?://)?player\.vimeo\.com/video/([0-9]+)',
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)
        return None
    
    @staticmethod
    def fetch_youtube_metadata(video_id: str) -> Dict:
        """Fetch metadata dari YouTube"""
        try:
            # Coba pakai oEmbed API (no API key required)
            return ContentMetadataService._fetch_youtube_oembed(video_id)
        except Exception as e:
            print(f"Error fetching YouTube metadata via oEmbed: {e}")
            # Fallback ke basic info
            return ContentMetadataService._fetch_youtube_basic(video_id)
    
    @staticmethod
    def _fetch_youtube_oembed(video_id: str) -> Dict:
        """Fetch YouTube metadata via oEmbed API"""
        try:
            oembed_url = "https://www.youtube.com/oembed"
            params = {
                'url': f'https://www.youtube.com/watch?v={video_id}',
                'format': 'json'
            }
            
            response = requests.get(oembed_url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            return {
                'success': True,
                'title': data.get('title', ''),
                'author_name': data.get('author_name', ''),
                'thumbnail_url': data.get('thumbnail_url', f'https://img.youtube.com/vi/{video_id}/hqdefault.jpg'),
                'provider_name': 'YouTube',
            }
        except Exception as e:
            print(f"oEmbed error: {e}")
            raise
    
    @staticmethod
    def _fetch_youtube_basic(video_id: str) -> Dict:
        """Fallback method untuk YouTube basic info"""
        return {
            'success': True,
            'title': '',
            'thumbnail_url': f'https://img.youtube.com/vi/{video_id}/hqdefault.jpg',
            'provider_name': 'YouTube',
        }
    
    @staticmethod
    def fetch_spotify_metadata(item_type: str, item_id: str) -> Dict:
        """Fetch metadata dari Spotify via oEmbed"""
        try:
            url = "https://open.spotify.com/oembed"
            params = {
                'url': f'https://open.spotify.com/{item_type}/{item_id}',
                'format': 'json'
            }
            
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            return {
                'success': True,
                'title': data.get('title', ''),
                'description': data.get('description', ''),
                'thumbnail_url': data.get('thumbnail_url', ''),
                'author_name': data.get('author_name', ''),
                'provider_name': 'Spotify',
            }
        except Exception as e:
            print(f"Error fetching Spotify metadata: {e}")
            return {
                'success': False,
                'title': '',
                'provider_name': 'Spotify',
            }
    
    @staticmethod
    def fetch_vimeo_metadata(video_id: str) -> Dict:
        """Fetch metadata dari Vimeo"""
        try:
            # Vimeo simple API (no auth required for public videos)
            url = f"https://vimeo.com/api/v2/video/{video_id}.json"
            
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data and len(data) > 0:
                video_data = data[0]
                return {
                    'success': True,
                    'title': video_data.get('title', ''),
                    'description': video_data.get('description', ''),
                    'thumbnail_url': video_data.get('thumbnail_large', ''),
                    'duration': video_data.get('duration', 0),
                    'author_name': video_data.get('user_name', ''),
                    'provider_name': 'Vimeo',
                }
        except Exception as e:
            print(f"Error fetching Vimeo metadata: {e}")
        
        return {
            'success': False,
            'title': '',
            'provider_name': 'Vimeo',
        }
    
    @staticmethod
    def analyze_url(url: str) -> Dict:
        """Analisis URL dan return comprehensive metadata"""
        result = {
            'is_valid': False,
            'provider': None,
            'type': None,
            'id': None,
            'metadata': {},
            'embed_code': '',
            'supports_embed': False,
            'content_type': None,
            'recommended_categories': [],
        }
        
        url = url.strip()
        if not url:
            return result
        
        # Check YouTube
        video_id = ContentMetadataService.extract_youtube_video_id(url)
        if video_id:
            result['is_valid'] = True
            result['provider'] = 'youtube'
            result['type'] = 'video'
            result['id'] = video_id
            result['supports_embed'] = True
            result['content_type'] = 'embedded_video'
            result['metadata'] = ContentMetadataService.fetch_youtube_metadata(video_id)
            
            # Generate embed code untuk Lansia (controls besar, autoplay off)
            result['embed_code'] = f'''
            <iframe 
                width="560" 
                height="315" 
                src="https://www.youtube.com/embed/{video_id}?rel=0&controls=1&showinfo=1&modestbranding=1" 
                frameborder="0" 
                allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                allowfullscreen>
            </iframe>
            '''
            
            # Recommended categories untuk YouTube video
            result['recommended_categories'] = ['senam_lansia', 'kesehatan_praktis', 'tutorial_aplikasi']
            return result
        
        # Check Spotify
        spotify_data = ContentMetadataService.extract_spotify_id(url)
        if spotify_data:
            item_type, item_id = spotify_data
            result['is_valid'] = True
            result['provider'] = 'spotify'
            result['type'] = item_type
            result['id'] = item_id
            result['supports_embed'] = True
            result['content_type'] = 'embedded_audio'
            result['metadata'] = ContentMetadataService.fetch_spotify_metadata(item_type, item_id)
            
            # Spotify embed code
            result['embed_code'] = f'''
            <iframe 
                src="https://open.spotify.com/embed/{item_type}/{item_id}" 
                width="300" 
                height="380" 
                frameborder="0" 
                allowtransparency="true" 
                allow="encrypted-media">
            </iframe>
            '''
            
            # Recommended categories untuk Spotify
            if item_type in ['episode', 'show']:
                result['recommended_categories'] = ['kesehatan_praktis', 'obat_dan_pengobatan', 'keluarga_tips']
            else:
                result['recommended_categories'] = ['relaksasi', 'komunitas_cerita']
            return result
        
        # Check Vimeo
        vimeo_id = ContentMetadataService.extract_vimeo_id(url)
        if vimeo_id:
            result['is_valid'] = True
            result['provider'] = 'vimeo'
            result['type'] = 'video'
            result['id'] = vimeo_id
            result['supports_embed'] = True
            result['content_type'] = 'embedded_video'
            result['metadata'] = ContentMetadataService.fetch_vimeo_metadata(vimeo_id)
            
            # Vimeo embed code
            result['embed_code'] = f'''
            <iframe 
                src="https://player.vimeo.com/video/{vimeo_id}" 
                width="640" 
                height="360" 
                frameborder="0" 
                allow="autoplay; fullscreen" 
                allowfullscreen>
            </iframe>
            '''
            
            result['recommended_categories'] = ['senam_lansia', 'tutorial_aplikasi', 'komunitas_cerita']
            return result
        
        return result
    
    @staticmethod
    def get_supported_platforms() -> Dict:
        """Get list of supported platforms"""
        return {
            'youtube': {
                'name': 'YouTube',
                'types': ['video'],
                'icon': '🎬',
                'description': 'Video pendek (1-5 menit) untuk lansia',
                'example_urls': [
                    'https://youtu.be/dQw4w9WgXcQ',
                    'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                ]
            },
            'spotify': {
                'name': 'Spotify',
                'types': ['audio', 'podcast'],
                'icon': '🎧',
                'description': 'Audio podcast singkat (3-10 menit)',
                'example_urls': [
                    'https://open.spotify.com/episode/...',
                    'https://open.spotify.com/track/...',
                ]
            },
            'vimeo': {
                'name': 'Vimeo',
                'types': ['video'],
                'icon': '📹',
                'description': 'Video kualitas tinggi',
                'example_urls': [
                    'https://vimeo.com/123456789',
                ]
            }
        }