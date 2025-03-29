import time
import requests
import pandas as pd

def fetch_top_artists(country, api_key):
    """Fetches top 1000 artists from Last.fm API for a given country."""
    API_URL = "https://ws.audioscrobbler.com/2.0/?method=geo.gettopartists&country={}&api_key={}&format=json&limit=1000"
    response = requests.get(API_URL.format(country, api_key))
    time.sleep(2)  # Delay necessary to respect API rate limits
    
    if response.status_code == 200:
        return response.json().get("topartists", {}).get("artist", [])
    else:
        print(f"Failed to fetch data for {country}. Status Code: {response.status_code}")
        return []

def load_data():
    """Loads country list and artist-label mapping."""
    countries_df = pd.read_csv("data/countries_regions.csv", header=None)
    labels_df = pd.read_csv("data/music_labels_artists.csv")
    labels_df.columns = ["artist", "label"]
    return countries_df.iloc[:, 0].tolist(), labels_df

def process_data(countries, labels_df, api_key):
    """Processes the data by fetching top artists and aggregating listener counts per label."""
    label_market_share = {}
    
    for country in countries:
        print(f"Fetching data for {country}...")
        artists = fetch_top_artists(country, api_key)
        
        for artist in artists:
            artist_name = artist["name"]
            listeners = int(artist["listeners"])
            
            # Find the label associated with the artist
            label_row = labels_df[labels_df["artist"] == artist_name]
            if not label_row.empty:
                label = label_row.iloc[0]["label"]
                
                # Update label market share data
                if country not in label_market_share:
                    label_market_share[country] = {}
                
                if label not in label_market_share[country]:
                    label_market_share[country][label] = 0
                
                label_market_share[country][label] += listeners
    
    return label_market_share

def save_results(label_market_share):
    """Saves the aggregated data to a CSV file."""
    output_data = []
    for country, labels in label_market_share.items():
        for label, listeners in labels.items():
            output_data.append([country, label, listeners])
    
    output_df = pd.DataFrame(output_data, columns=["Country", "Label", "Listeners"])
    output_df.to_csv("label_market_share.csv", index=False)
    print("Data collection complete. Results saved to 'label_market_share.csv'.")

def final_execution(api_key):
    """Main function to execute the full process."""
    countries, labels_df = load_data()
    label_market_share = process_data(countries, labels_df, api_key)
    save_results(label_market_share)

if __name__ == "__main__":
    final_execution("YOUR_API_KEY_HERE")