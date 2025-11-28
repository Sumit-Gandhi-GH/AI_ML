# Sales Database Schema

## Tables

### LEADS
| Column Name | Type | Description |
|---|---|---|
| lead_id | INTEGER | Unique identifier for the lead |
| first_name | TEXT | First name of the lead |
| last_name | TEXT | Last name of the lead |
| email | TEXT | Email address of the lead |
| phone | TEXT | Phone number of the lead |
| source | TEXT | Source of the lead (e.g., 'Web', 'Referral', 'Partner') |
| status | TEXT | Current status (e.g., 'New', 'Contacted', 'Qualified', 'Lost') |
| created_at | DATETIME | Timestamp when the lead was created |

### DEALS
| Column Name | Type | Description |
|---|---|---|
| deal_id | INTEGER | Unique identifier for the deal |
| lead_id | INTEGER | Foreign key linking to LEADS table |
| rep_id | INTEGER | Foreign key linking to SALES_REPS table |
| amount | FLOAT | Value of the deal |
| stage | TEXT | Sales stage (e.g., 'Prospecting', 'Negotiation', 'Closed Won', 'Closed Lost') |
| close_date | DATE | Expected or actual close date |
| created_at | DATETIME | Timestamp when the deal was created |

### SALES_REPS
| Column Name | Type | Description |
|---|---|---|
| rep_id | INTEGER | Unique identifier for the sales representative |
| name | TEXT | Full name of the sales rep |
| region | TEXT | Sales region assigned to the rep (e.g., 'North', 'South', 'East', 'West') |
| quota | FLOAT | Quarterly sales quota |
| email | TEXT | Email address of the sales rep |

### REVENUE
| Column Name | Type | Description |
|---|---|---|
| revenue_id | INTEGER | Unique identifier for the revenue record |
| deal_id | INTEGER | Foreign key linking to DEALS table |
| amount | FLOAT | Revenue amount recognized |
| recognition_date | DATE | Date when revenue was recognized |

## Sample Questions
- "How many new leads were created last week?"
- "What is the total value of deals in the 'Negotiation' stage?"
- "Which sales rep has the highest win rate?"
- "Show me the monthly revenue for the last year."
- "List all leads from the 'Web' source."
