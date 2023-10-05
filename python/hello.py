import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import csv
from datetime import datetime
import csv
import boto3
import os

def lambda_handler(event, context):
 
        client_id = 'Your client ID'
        client_secret = 'Client secret key'
        client_credentials_manager = SpotifyClientCredentials(client_id=client_id, client_secret=client_secret)
        sp = spotipy.Spotify(client_credentials_manager=client_credentials_manager)
        playlist_uri = '37i9dQZEVXbMWDif5SCBJq'
 
        def get_playlist_tracks(playlist_uri):
            results = sp.playlist_tracks(playlist_uri)
            
            for track in results['items']:
                    track_info = track['track']
                    track_name = track_info['name']
                    artists = [track_info['artists'][0]['name']]
                    first_artist = artists[0] if artists else 'N/A' 
                    album_name = track_info['album']['name']
                    release_date = track_info['album']['release_date']
                    duration = track_info ['duration_ms']

            filename = f'/tmp/spotify_{datetime.now().strftime("%m_%d_%Y")}.csv'   
            with open(filename, mode='w', newline='') as csv_file:
                fieldnames = ['Track Name', 'Artist', 'Album', 'Release Date', 'Duration']
                writer = csv.DictWriter(csv_file, fieldnames=fieldnames)
                writer.writeheader()

                for track in results['items']:
                    track_info = track['track']
                    track_name = track_info['name']
                    artists = [track_info['artists'][0]['name']]
                    first_artist = artists[0] if artists else 'N/A' 
                    album_name = track_info['album']['name']
                    release_date = track_info['album']['release_date']
                    duration = track_info ['duration_ms']
                    writer.writerow({'Track Name': track_name, 'Artist': first_artist, 'Album': album_name, 'Release Date': release_date, 'Duration' : duration})

            return filename

        def upload_to_s3(csv_file_path,bucket_name,s3_key):
            s3 = boto3.client('s3')
            s3.upload_file(csv_file_path,bucket_name,s3_key)
 
        csv_file_path=get_playlist_tracks(playlist_uri)
        bucket_name = 'spotifydatatos3'
        s3_key = f'new/spotify_{datetime.now().strftime("%m_%d_%y")}.csv'
        upload_to_s3(csv_file_path,bucket_name,s3_key)
        return {
            'statusCode':200,
            'body':'CSV file uploaded to S3'
        }