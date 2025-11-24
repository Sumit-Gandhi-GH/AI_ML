headers_str = "first_name, last_name, full_name, linkedin, sales_navigator, open, premium, open_to_work, headline, industry, email, email_status, personal_email, num_of_connections, location, skills, twitter, about, birthday, pronouns, time_in_position, time_in_company, changed_job, job_details, latest_post, company_name, company_link, company_id, company_domain, company_about, company_founded, company_size, company_location_1, company_location_2, company_location_3, company_city_1, company_city_2, company_city_3, company_address, company_postal_code, company_phone, company_industry_1, company_industry_2, company_industry_3, domain_status, company_specialties, company_size_category, social_fields, keywords, annual_revenue, technologies, funding_events, total_funding, last_funding_round_date, last_funding_stage, alexa_ranking, crunchbase_url, market_cap, current_position_1, current_position_2, current_position_3, position_1, position_2, position_3, position_date_1, position_date_2, position_date_3, education_1, education_2, education_3, education_date_1, education_date_2, education_date_3, website_1, website_2, website_3, phone_number_1, phone_number_2, phone_number_3, emails, position, filtered, filter_message, company_email"

headers = [h.strip() for h in headers_str.split(',')]

print(f"Total headers: {len(headers)}")

# Check for duplicates
seen = set()
duplicates = []
for h in headers:
    if h in seen:
        duplicates.append(h)
    seen.add(h)

if duplicates:
    print(f"Found duplicate headers: {duplicates}")
else:
    print("No duplicate headers found.")

# Check for special characters
import re
special_chars = []
for h in headers:
    if not re.match(r'^[a-zA-Z0-9_]+$', h):
        special_chars.append(h)

if special_chars:
    print(f"Headers with special characters (might be fine, just checking): {special_chars}")
else:
    print("All headers are alphanumeric + underscore.")
