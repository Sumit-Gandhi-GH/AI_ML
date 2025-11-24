import requests
import pandas as pd
import io

URL = "http://localhost:5000/api/upload"
HEADERS = "first_name, last_name, full_name, linkedin, sales_navigator, open, premium, open_to_work, headline, industry, email, email_status, personal_email, num_of_connections, location, skills, twitter, about, birthday, pronouns, time_in_position, time_in_company, changed_job, job_details, latest_post, company_name, company_link, company_id, company_domain, company_about, company_founded, company_size, company_location_1, company_location_2, company_location_3, company_city_1, company_city_2, company_city_3, company_address, company_postal_code, company_phone, company_industry_1, company_industry_2, company_industry_3, domain_status, company_specialties, company_size_category, social_fields, keywords, annual_revenue, technologies, funding_events, total_funding, last_funding_round_date, last_funding_stage, alexa_ranking, crunchbase_url, market_cap, current_position_1, current_position_2, current_position_3, position_1, position_2, position_3, position_date_1, position_date_2, position_date_3, education_1, education_2, education_3, education_date_1, education_date_2, education_date_3, website_1, website_2, website_3, phone_number_1, phone_number_2, phone_number_3, emails, position, filtered, filter_message, company_email"

headers_list = [h.strip() for h in HEADERS.split(',')]

# Create a DataFrame with these headers and some dummy data (including NaNs)
data = {h: [f"value_{i}_{h}" for i in range(5)] for h in headers_list}
# Add some NaNs
data['first_name'][0] = None
data['email'][2] = None

df = pd.DataFrame(data)

# Save to CSV in memory
csv_buffer = io.StringIO()
df.to_csv(csv_buffer, index=False)
csv_content = csv_buffer.getvalue()

print(f"Uploading CSV with {len(headers_list)} columns...")

try:
    files = {'file': ('test_headers.csv', csv_content, 'text/csv')}
    response = requests.post(URL, files=files)
    
    print(f"Status Code: {response.status_code}")
    print("Response Body:")
    print(response.text)
    
    if response.status_code == 200:
        json_resp = response.json()
        print("Upload successful!")
        print(f"Session ID: {json_resp.get('session_id')}")
        print(f"Preview rows: {len(json_resp.get('preview'))}")
    else:
        print("Upload failed!")

except Exception as e:
    print(f"Request failed: {e}")
