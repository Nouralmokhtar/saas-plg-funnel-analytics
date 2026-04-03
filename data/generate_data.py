"""
Generate synthetic SaaS product data for portfolio project.
Simulates a B2B SaaS platform with trial-to-paid conversion funnel.

How to run:
    python generate_data.py
"""

import csv
import random
from datetime import datetime, timedelta

random.seed(99)

# === SETTINGS ===
NUM_ACCOUNTS = 1500
START_DATE = datetime(2023, 1, 1)
END_DATE = datetime(2024, 12, 31)

INDUSTRIES = ["E-commerce", "SaaS", "Fintech", "Healthcare", "Education", "Marketing Agency", "Logistics", "Real Estate"]
PLANS = ["Free", "Starter", "Growth", "Enterprise"]
SOURCES = ["Organic Search", "Paid Ads", "Referral", "Product Hunt", "LinkedIn", "Direct", "Partner"]
COMPANY_SIZES = ["1-10", "11-50", "51-200", "201-500", "500+"]
FEATURES = [
    "Dashboard", "Reports", "Integrations", "API Access",
    "Team Collaboration", "Custom Workflows", "Advanced Analytics",
    "Export Data", "Automations", "Single Sign-On"
]


def random_date(start, end):
    if end < start:
        end = start
    days = (end - start).days
    if days <= 0:
        return start
    return start + timedelta(days=random.randint(0, days))


def generate_accounts():
    """Create company/account records with signup and plan info."""
    accounts = []

    for i in range(1, NUM_ACCOUNTS + 1):
        signup_date = random_date(START_DATE, END_DATE)
        source = random.choice(SOURCES)
        company_size = random.choice(COMPANY_SIZES)
        industry = random.choice(INDUSTRIES)

        # Trial to paid conversion depends on source and company size
        if source in ["Referral", "Partner"]:
            convert_chance = 0.35
        elif source == "Organic Search":
            convert_chance = 0.22
        else:
            convert_chance = 0.15

        # Bigger companies more likely to convert
        if company_size in ["51-200", "201-500", "500+"]:
            convert_chance += 0.10

        # Determine plan
        converted = random.random() < convert_chance
        if converted:
            if company_size in ["201-500", "500+"]:
                plan = random.choices(["Starter", "Growth", "Enterprise"], weights=[0.15, 0.45, 0.40], k=1)[0]
            elif company_size == "51-200":
                plan = random.choices(["Starter", "Growth", "Enterprise"], weights=[0.30, 0.50, 0.20], k=1)[0]
            else:
                plan = random.choices(["Starter", "Growth", "Enterprise"], weights=[0.55, 0.35, 0.10], k=1)[0]
            trial_end = signup_date + timedelta(days=14)
            conversion_date = random_date(trial_end, trial_end + timedelta(days=7))
        else:
            plan = "Free"
            conversion_date = None
            trial_end = signup_date + timedelta(days=14)

        # MRR based on plan
        if plan == "Starter":
            mrr = random.choice([29, 49, 49, 79])
        elif plan == "Growth":
            mrr = random.choice([149, 199, 249, 299])
        elif plan == "Enterprise":
            mrr = random.choice([499, 799, 999, 1499])
        else:
            mrr = 0

        # Churn for paid accounts
        churned = False
        churn_date = None
        if converted and random.random() < 0.25:
            churned = True
            churn_date = random_date(
                conversion_date + timedelta(days=30),
                min(conversion_date + timedelta(days=365), END_DATE)
            )

        accounts.append({
            "account_id": f"A{i:05d}",
            "signup_date": signup_date.strftime("%Y-%m-%d"),
            "industry": industry,
            "company_size": company_size,
            "source": source,
            "plan": plan,
            "mrr": mrr,
            "trial_end_date": trial_end.strftime("%Y-%m-%d"),
            "conversion_date": conversion_date.strftime("%Y-%m-%d") if conversion_date else "",
            "churned": "Yes" if churned else "No",
            "churn_date": churn_date.strftime("%Y-%m-%d") if churn_date else "",
        })

    return accounts


def generate_feature_usage(accounts):
    """Track which features each account uses and how often."""
    usage = []
    usage_id = 1

    for account in accounts:
        signup = datetime.strptime(account["signup_date"], "%Y-%m-%d")
        plan = account["plan"]

        # How many features they use depends on plan
        if plan == "Enterprise":
            features_used = random.sample(FEATURES, random.randint(6, 10))
            months_active = random.randint(3, 12)
        elif plan == "Growth":
            features_used = random.sample(FEATURES, random.randint(4, 8))
            months_active = random.randint(2, 10)
        elif plan == "Starter":
            features_used = random.sample(FEATURES, random.randint(2, 5))
            months_active = random.randint(1, 8)
        else:
            features_used = random.sample(FEATURES, random.randint(1, 3))
            months_active = random.randint(1, 3)

        for month_offset in range(months_active):
            usage_month = signup + timedelta(days=30 * month_offset)
            if usage_month > END_DATE:
                break

            for feature in features_used:
                # Usage count varies by feature importance
                if feature in ["Dashboard", "Reports"]:
                    times_used = random.randint(10, 100)
                elif feature in ["Integrations", "API Access"]:
                    times_used = random.randint(1, 30)
                else:
                    times_used = random.randint(3, 50)

                usage.append({
                    "usage_id": f"U{usage_id:07d}",
                    "account_id": account["account_id"],
                    "feature": feature,
                    "usage_month": usage_month.strftime("%Y-%m"),
                    "times_used": times_used,
                })
                usage_id += 1

    return usage


def generate_support_tickets(accounts):
    """Create support ticket data to track customer health."""
    tickets = []
    ticket_id = 1

    CATEGORIES = ["Bug Report", "Feature Request", "Billing", "Onboarding Help", "Integration Issue", "Performance"]
    PRIORITIES = ["Low", "Medium", "High", "Critical"]

    for account in accounts:
        signup = datetime.strptime(account["signup_date"], "%Y-%m-%d")
        plan = account["plan"]

        # Number of tickets based on engagement
        if plan == "Enterprise":
            num_tickets = random.randint(2, 15)
        elif plan in ["Growth", "Starter"]:
            num_tickets = random.randint(0, 8)
        else:
            num_tickets = random.randint(0, 3)

        for _ in range(num_tickets):
            created = random_date(signup, END_DATE)
            category = random.choice(CATEGORIES)
            priority = random.choices(PRIORITIES, weights=[0.30, 0.40, 0.20, 0.10], k=1)[0]

            # Resolution time depends on priority
            if priority == "Critical":
                resolution_hours = random.randint(1, 8)
            elif priority == "High":
                resolution_hours = random.randint(4, 48)
            elif priority == "Medium":
                resolution_hours = random.randint(12, 96)
            else:
                resolution_hours = random.randint(24, 168)

            resolved = random.choices(["Yes", "No"], weights=[0.85, 0.15], k=1)[0]

            tickets.append({
                "ticket_id": f"T{ticket_id:06d}",
                "account_id": account["account_id"],
                "created_date": created.strftime("%Y-%m-%d"),
                "category": category,
                "priority": priority,
                "resolution_hours": resolution_hours if resolved == "Yes" else "",
                "resolved": resolved,
            })
            ticket_id += 1

    return tickets


def generate_events(accounts):
    """Create key product events (activation milestones)."""
    events = []
    event_id = 1

    EVENT_TYPES = [
        "Signed Up",
        "Completed Onboarding",
        "Invited Team Member",
        "Created First Report",
        "Connected Integration",
        "Upgraded Plan",
        "Enabled Automation",
        "Exported Data",
    ]

    for account in accounts:
        signup = datetime.strptime(account["signup_date"], "%Y-%m-%d")
        plan = account["plan"]

        # Everyone signs up
        events.append({
            "event_id": f"E{event_id:07d}",
            "account_id": account["account_id"],
            "event_type": "Signed Up",
            "event_date": signup.strftime("%Y-%m-%d"),
        })
        event_id += 1

        # Onboarding completion depends on plan
        if plan != "Free":
            onboard_chance = 0.80
        else:
            onboard_chance = 0.45

        if random.random() < onboard_chance:
            onboard_date = signup + timedelta(days=random.randint(0, 5))
            events.append({
                "event_id": f"E{event_id:07d}",
                "account_id": account["account_id"],
                "event_type": "Completed Onboarding",
                "event_date": onboard_date.strftime("%Y-%m-%d"),
            })
            event_id += 1

        # Other activation events
        remaining = EVENT_TYPES[2:]  # skip signup and onboarding
        if plan == "Enterprise":
            num_events = random.randint(3, len(remaining))
        elif plan == "Growth":
            num_events = random.randint(2, 5)
        elif plan == "Starter":
            num_events = random.randint(1, 3)
        else:
            num_events = random.randint(0, 2)

        chosen = random.sample(remaining, min(num_events, len(remaining)))
        for evt in chosen:
            evt_date = random_date(signup, min(signup + timedelta(days=90), END_DATE))
            events.append({
                "event_id": f"E{event_id:07d}",
                "account_id": account["account_id"],
                "event_type": evt,
                "event_date": evt_date.strftime("%Y-%m-%d"),
            })
            event_id += 1

    return events


def save_to_csv(data, filename, fieldnames):
    with open(filename, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(data)
    print(f"  Saved {len(data)} rows to {filename}")


# === MAIN ===
if __name__ == "__main__":
    print("Generating SaaS product data...")
    print()

    accounts = generate_accounts()
    feature_usage = generate_feature_usage(accounts)
    tickets = generate_support_tickets(accounts)
    events = generate_events(accounts)

    save_to_csv(accounts, "accounts.csv",
                ["account_id", "signup_date", "industry", "company_size", "source",
                 "plan", "mrr", "trial_end_date", "conversion_date", "churned", "churn_date"])

    save_to_csv(feature_usage, "feature_usage.csv",
                ["usage_id", "account_id", "feature", "usage_month", "times_used"])

    save_to_csv(tickets, "support_tickets.csv",
                ["ticket_id", "account_id", "created_date", "category", "priority",
                 "resolution_hours", "resolved"])

    save_to_csv(events, "product_events.csv",
                ["event_id", "account_id", "event_type", "event_date"])

    print()
    print("Done! All CSV files are ready.")
    print(f"  Accounts:      {len(accounts)}")
    print(f"  Feature Usage: {len(feature_usage)}")
    print(f"  Tickets:       {len(tickets)}")
    print(f"  Events:        {len(events)}")
