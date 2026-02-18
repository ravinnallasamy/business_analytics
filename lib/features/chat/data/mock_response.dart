
final Map<String, dynamic> mockSalesResponse = {
  "status": "success",
  "summary": "Sales Summary for December 2025",
  "blocks": [
    {
      "type": "text",
      "content": "# Sales Performance Report - December 2025\n\nHere is the consolidated sales performance for **December 2025** across all regions.\n\n## Key Highlights\n\n- Net revenue grew by **15%** compared to November 2025\n- Return rate reduced to **0.67%** from 1.2%\n- Top performing zone: **South Zone** with Rs.2500 Lacs revenue\n\n> **Note:** All values are in Indian Rupees (Lacs) unless specified otherwise."
    },
    {
      "type": "metrics",
      "metrics": [
        { "label": "NET REVENUE", "value": "Rs.6100.96 Lacs", "raw_value": 6100.96 },
        { "label": "SALES REVENUE", "value": "Rs.6141.73 Lacs", "raw_value": 6141.73 },
        { "label": "RETURN REVENUE", "value": "Rs.40.77 Lacs", "raw_value": 40.77 },
        { "label": "NET SQM", "value": "2,166,930.66", "raw_value": 2166930.66 },
        { "label": "NET QTY", "value": "1,919,929", "raw_value": 1919929 },
        { "label": "RETURN QTY", "value": "13,063", "raw_value": 13063 }
      ]
    },
    {
      "type": "text",
      "content": "## Top Dealers by Revenue\n\nBelow are the **top 5 dealers** sorted by highest revenue contribution this month."
    },
    {
      "type": "table",
      "title": "Top 5 Priority Dealers for Tomorrow",
      "description": "Sorted by highest outstanding balance requiring immediate intervention.",
      "headers": ["Dealer Name", "Outstanding (Rs.)", "FY Revenue (Rs.)", "Oldest Invoice"],
      "rows": [
        ["Dp Tiles And Sanitary", "Rs.3.16 Crores", "Rs.6.05 Crores", "29 Oct 2025"],
        ["K S R Ceramics", "Rs.1.82 Crores", "Rs.3.95 Crores", "15 Oct 2025"],
        ["Kamlesh Trading And Marketing", "Rs.1.77 Crores", "Rs.4.12 Crores", "27 Oct 2025"],
        ["Impact Tiles Gallery", "Rs.1.63 Crores", "Rs.5.34 Crores", "24 Oct 2025"],
        ["Sacistha Granite", "Rs.1.29 Crores", "Rs.3.20 Crores", "30 Oct 2025"]
      ],
      "total_rows": 10
    },
    {
      "type": "chart",
      "chart_type": "bar",
      "title": "Monthly Revenue Trend (Last 6 Months)",
      "x_key": "month",
      "y_keys": ["sales", "returns"],
      "data": [
        { "month": "Jul 2025", "sales": 5200, "returns": 120 },
        { "month": "Aug 2025", "sales": 4800, "returns": 95 },
        { "month": "Sep 2025", "sales": 5500, "returns": 110 },
        { "month": "Oct 2025", "sales": 5900, "returns": 85 },
        { "month": "Nov 2025", "sales": 5300, "returns": 70 },
        { "month": "Dec 2025", "sales": 6141, "returns": 40 }
      ]
    },
    {
      "type": "text",
      "content": "### Mentor's Action Plan\n\n**Critical Intervention - Dp Tiles And Sanitary:** Their outstanding is over **50%** of their total FY revenue. Schedule an urgent meeting.\n\n**Follow-up Required - K S R Ceramics:** Payment pending since **15 Oct 2025**. Send a reminder and escalate if no response by end of week."
    },
    {
      "type": "suggestions",
      "items": [
        "Show dealer visit plan for tomorrow",
        "Compare with last month sales",
        "Show product-wise sales breakdown",
        "Which dealers have outstanding over 60 days?"
      ]
    }
  ]
};
