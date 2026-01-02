import re
import requests
import logging
from typing import Optional, Dict, Tuple, Any
from urllib.parse import urlparse, parse_qs

# Konfigurasi Logging
logger = logging.getLogger(__name__)

class ContentMetadataService:
    """
    Service metadata yang dioptimalkan dengan Hybrid Parsing (URLParse + Regex).
    Fokus: Kecepatan, Ketepatan, dan Toleransi terhadap format URL yang berantakan.
    """
    
    YOUTUBE_OEMBED_URL = "https://www.youtube.com/oembed"
    SPOTIFY_OEMBED_URL = "https://open.spotify.com/oembed"
    VIMEO_OEMBED_URL = "https://vimeo.com/api/oembed.json"

    @staticmethod
    def extract_youtube_video_id(url: str) -> Optional[str]:
        """
        Extract YouTube Video ID dengan strategi Hybrid (Parse -> Regex).
        Menangani semua format standar dan short link.
        """
        if not url:
            return None

        url = url.strip()
        
        # 1. Normalisasi URL (tambahkan https jika tidak ada)
        # Ini penting agar urlparse bekerja dengan benar pada input 'www.youtube.com...'
        if not url.startswith(('http://', 'https://')):
            url = 'https://' + url

        try:
            # 2. Coba Parsing Standar (Paling Aman untuk parameter v=...)
            parsed = urlparse(url)
            hostname = parsed.hostname.lower() if parsed.hostname else ""

            # Case A: youtube.com (Standard)
            if 'youtube.com' in hostname:
                query = parse_qs(parsed.query)
                if 'v' in query:
                    return query['v'][0]
                
                # Handle path based IDs (embed/v/shorts)
                path_parts = parsed.path.strip('/').split('/')
                if len(path_parts) >= 2 and path_parts[0] in ['embed', 'v', 'shorts']:
                    return path_parts[1]

            # Case B: youtu.be (Shortened)
            if 'youtu.be' in hostname:
                return parsed.path.strip('/')
                
        except Exception as e:
            logger.warning(f"URLParse failed, switching to Regex fallback: {e}")

        # 3. Fallback Regex Master (Jaring Pengaman Terakhir)
        # Menangkap pola 11 karakter ID di berbagai posisi umum
        patterns = [
            r'(?:v=|/)([0-9A-Za-z_-]{11})(?:[?&/]|$)',  # Menangkap setelah v= atau /
            r'(?:youtu\.be/|embed/|shorts/)([0-9A-Za-z_-]{11})', # Format path khusus
        ]
        
        for pattern in patterns:
            match = re.search(pattern, url, re.IGNORECASE)
            if match:
                return match.group(1)
                
        return None

    @staticmethod
    def extract_spotify_id(url: str) -> Optional[Tuple[str, str]]:
        """Extract Spotify type dan ID"""
        # Support format: open.spotify.com/type/id atau spoti.fi/id (resolved)
        pattern = r'(?:open\.spotify\.com|spoti\.fi)/(track|episode|playlist|album|show)/([a-zA-Z0-9]+)'
        match = re.search(pattern, url, re.IGNORECASE)
        if match:
            return match.group(1), match.group(2)
        return None

    @staticmethod
    def extract_vimeo_id(url: str) -> Optional[str]:
        """Extract Vimeo Video ID."""
        pattern = r'(?:vimeo\.com|player\.vimeo\.com/video)/([0-9]+)'
        match = re.search(pattern, url, re.IGNORECASE)
        if match:
            return match.group(1)
        return None

    @staticmethod
    def fetch_oembed_data(oembed_url: str, content_url: str) -> Dict[str, Any]:
        """Helper generic untuk mengambil data oEmbed dengan Timeout"""
        try:
            params = {'url': content_url, 'format': 'json'}
            # Timeout 8 detik agar tidak blocking lama
            response = requests.get(oembed_url, params=params, timeout=8)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.warning(f"Failed to fetch oEmbed data from {oembed_url}: {e}")
            return {}

    @staticmethod
    def analyze_url(url: str) -> Dict[str, Any]:
        """
        Main logic analisis URL
        """
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
            'error': None
        }

        url = url.strip()
        if not url:
            result['error'] = "URL kosong"
            return result

        # --- 1. YOUTUBE ---
        # Cek domain youtube/youtu.be (case insensitive)
        if 'youtu' in url.lower():
            yt_id = ContentMetadataService.extract_youtube_video_id(url)
            
            if yt_id:
                result['is_valid'] = True
                result['provider'] = 'youtube'
                result['type'] = 'video'
                result['id'] = yt_id
                result['supports_embed'] = True
                result['content_type'] = 'embedded_video'
                result['recommended_categories'] = ['senam_lansia', 'kesehatan_praktis', 'tutorial_aplikasi']
                
                # Fetch Metadata via oEmbed
                meta = ContentMetadataService.fetch_oembed_data(
                    ContentMetadataService.YOUTUBE_OEMBED_URL, 
                    f"https://www.youtube.com/watch?v={yt_id}"
                )
                
                result['metadata'] = {
                    'title': meta.get('title', ''),
                    'author_name': meta.get('author_name', ''),
                    'thumbnail_url': meta.get('thumbnail_url', f"https://img.youtube.com/vi/{yt_id}/hqdefault.jpg"),
                    'provider_name': 'YouTube'
                }
                
                # Custom Embed Code (Optimasi untuk Lansia: controls besar, no autoplay)
                result['embed_code'] = f'''
                <iframe 
                    width="100%" 
                    height="315" 
                    src="https://www.youtube.com/embed/{yt_id}?rel=0&controls=1&showinfo=0&modestbranding=1" 
                    frameborder="0" 
                    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" 
                    allowfullscreen>
                </iframe>
                '''
                return result
            else:
                logger.error(f"Failed to extract ID from YouTube URL: {url}")

        # --- 2. SPOTIFY ---
        if 'spotify' in url.lower():
            spotify_data = ContentMetadataService.extract_spotify_id(url)
            if spotify_data:
                item_type, item_id = spotify_data
                result['is_valid'] = True
                result['provider'] = 'spotify'
                result['type'] = item_type
                result['id'] = item_id
                result['supports_embed'] = True
                result['content_type'] = 'embedded_audio'
                
                if item_type in ['episode', 'show']:
                    result['recommended_categories'] = ['kesehatan_praktis', 'obat_dan_pengobatan', 'keluarga_tips']
                else:
                    result['recommended_categories'] = ['relaksasi', 'komunitas_cerita']

                # Fetch Metadata
                spotify_url = f"https://open.spotify.com/{item_type}/{item_id}"
                meta = ContentMetadataService.fetch_oembed_data(
                    ContentMetadataService.SPOTIFY_OEMBED_URL, 
                    spotify_url
                )
                
                result['metadata'] = {
                    'title': meta.get('title', ''),
                    'description': meta.get('description', ''),
                    'thumbnail_url': meta.get('thumbnail_url', ''),
                    'author_name': meta.get('author_name', ''),
                    'provider_name': 'Spotify'
                }

                # Embed Code Standard Spotify
                result['embed_code'] = f'''
                <iframe 
                    style="border-radius:12px" 
                    src="https://open.spotify.com/embed/{item_type}/{item_id}?utm_source=generator" 
                    width="100%" 
                    height="352" 
                    frameborder="0" 
                    allowfullscreen="" 
                    allow="autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture" 
                    loading="lazy">
                </iframe>
                '''
                return result

        # --- 3. VIMEO ---
        if 'vimeo' in url.lower():
            vimeo_id = ContentMetadataService.extract_vimeo_id(url)
            if vimeo_id:
                result['is_valid'] = True
                result['provider'] = 'vimeo'
                result['type'] = 'video'
                result['id'] = vimeo_id
                result['supports_embed'] = True
                result['content_type'] = 'embedded_video'
                result['recommended_categories'] = ['senam_lansia', 'tutorial_aplikasi']

                # Fetch Metadata
                vimeo_url = f"https://vimeo.com/{vimeo_id}"
                meta = ContentMetadataService.fetch_oembed_data(
                    ContentMetadataService.VIMEO_OEMBED_URL, 
                    vimeo_url
                )
                
                result['metadata'] = {
                    'title': meta.get('title', ''),
                    'description': meta.get('description', ''),
                    'thumbnail_url': meta.get('thumbnail_url', ''),
                    'duration': meta.get('duration', 0),
                    'author_name': meta.get('author_name', ''),
                    'provider_name': 'Vimeo'
                }

                result['embed_code'] = f'''
                <iframe 
                    src="https://player.vimeo.com/video/{vimeo_id}?h=0&title=0&byline=0&portrait=0" 
                    width="100%" 
                    height="360" 
                    frameborder="0" 
                    allow="autoplay; fullscreen; picture-in-picture" 
                    allowfullscreen>
                </iframe>
                '''
                return result

        # --- 4. UNSUPPORTED ---
        result['error'] = "Platform tidak didukung atau format URL salah"
        return result

    @staticmethod
    def get_supported_platforms() -> Dict[str, Any]:
        """Info platform yang didukung"""
        return {
            'youtube': {
                'name': 'YouTube',
                'types': ['video', 'shorts'],
                'icon': '🎬',
                'description': 'Video pendek & tutorial',
                'example_urls': ['https://youtube.com/watch?v=...', 'https://youtu.be/...']
            },
            'spotify': {
                'name': 'Spotify',
                'types': ['podcast', 'music'],
                'icon': '🎧',
                'description': 'Podcast kesehatan & relaksasi',
                'example_urls': ['https://open.spotify.com/episode/...']
            },
            'vimeo': {
                'name': 'Vimeo',
                'types': ['video'],
                'icon': '📹',
                'description': 'Video HD',
                'example_urls': ['https://vimeo.com/...']
            }
        }