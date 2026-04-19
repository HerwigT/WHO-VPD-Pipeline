import streamlit as st
from google.cloud import bigquery
from dotenv import load_dotenv
import plotly.graph_objects as go
import plotly.express as px
from plotly.subplots import make_subplots
from streamlit_plotly_events import plotly_events
import pandas as pd
import os

# 1. SETUP & DATA LOADING
load_dotenv()
st.set_page_config(page_title="WHO Health Insights", layout="wide")


@st.cache_data
def get_data():
    client = bigquery.Client()
    query = f"""
        SELECT 
            country_code, 
            country_name, 
            year, 
            disease_name, 
            reported_cases, 
            vax_name, 
            vax_coverage
        FROM `{os.getenv("GCP_PROJECT_ID")}.who_gold.fct_vax_vs_incidence`
        ORDER BY year ASC
    """
    return client.query(query).to_dataframe()


df = get_data()

# 2. SIDEBAR FILTERS
st.sidebar.header("Global Filters")

# Disease Selection
diseases = sorted(df["disease_name"].unique())
selected_disease = st.sidebar.selectbox("Select Disease / Group", diseases)

# Get the vaccine name associated with the selection for UI labels
current_vax = df[df["disease_name"] == selected_disease]["vax_name"].unique()[0]

# Country Comparison Selection
all_countries = sorted(df["country_name"].unique())
country_1 = st.sidebar.selectbox(
    "Primary Country",
    all_countries,
    index=all_countries.index("Afghanistan") if "Afghanistan" in all_countries else 0,
)
country_2 = st.sidebar.selectbox(
    "Comparison Country (Optional)", ["None"] + all_countries
)

# 3. MAIN HEADER
st.title("💉 Vaccination Impact Dashboard")
st.markdown(
    f"Exploring the relationship between **{current_vax}** and **{selected_disease}**"
)

# 4. DASHBOARD LAYOUT (SIDE-BY-SIDE)
section_left, section_right = st.columns(2)

# --- LEFT SECTION: TIMELINE & SUMMARY ---
with section_left:
    st.subheader("Historical Trend")

    chart_col, metric_col = st.columns([3, 1])

    fig = make_subplots(specs=[[{"secondary_y": True}]])

    def add_timeline(fig, country, color_cases, color_vax):
        c_df = df[
            (df["country_name"] == country) & (df["disease_name"] == selected_disease)
        ]
        if not c_df.empty:
            # Case Line
            fig.add_trace(
                go.Scatter(
                    x=c_df["year"],
                    y=c_df["reported_cases"],
                    name=f"{country} (Cases)",
                    line=dict(color=color_cases, width=3),
                ),
                secondary_y=False,
            )
            # Vax Line
            fig.add_trace(
                go.Scatter(
                    x=c_df["year"],
                    y=c_df["vax_coverage"],
                    name=f"{country} ({current_vax} %)",
                    line=dict(color=color_vax, width=2, dash="dot"),
                ),
                secondary_y=True,
            )

    add_timeline(fig, country_1, "#007BFF", "#66B2FF")  # Blue
    if country_2 != "None":
        add_timeline(fig, country_2, "#DC3545", "#FF8888")  # Red

    fig.update_layout(
        height=450,
        margin=dict(l=0, r=0, t=20, b=0),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        template="plotly_white",
        hovermode="x unified",
    )
    fig.update_yaxes(title_text="Reported Cases", secondary_y=False)
    fig.update_yaxes(title_text="Vax Coverage (%)", secondary_y=True, range=[0, 105])

    with chart_col:
        st.plotly_chart(fig, width="stretch")

    with metric_col:
        st.write("#### Summary")

        # Primary Country Stats
        c1_subset = df[
            (df["country_name"] == country_1) & (df["disease_name"] == selected_disease)
        ]
        if not c1_subset.empty:
            st.metric(country_1, f"{int(c1_subset['reported_cases'].max()):,} Peak")
            st.metric("Avg Vax", f"{c1_subset['vax_coverage'].mean():.1f}%")

        # Secondary Country Stats
        if country_2 != "None":
            st.divider()
            c2_subset = df[
                (df["country_name"] == country_2)
                & (df["disease_name"] == selected_disease)
            ]
            if not c2_subset.empty:
                st.metric(country_2, f"{int(c2_subset['reported_cases'].max()):,} Peak")
                st.metric("Avg Vax", f"{c2_subset['vax_coverage'].mean():.1f}%")

# --- RIGHT SECTION: GLOBAL MAP ---
with section_right:
    st.subheader(f"Global {current_vax} Coverage")

    # Map Year Slider
    map_year = st.slider(
        "Select Map Year",
        min_value=int(df["year"].min()),
        max_value=int(df["year"].max()),
        value=int(df["year"].max()),
        key="global_map_slider",
    )

    map_data = df[(df["year"] == map_year) & (df["disease_name"] == selected_disease)]

    if not map_data.empty:
        fig_map = px.choropleth(
            map_data,
            locations="country_code",
            color="vax_coverage",
            hover_name="country_name",
            color_continuous_scale="BuPu",
            range_color=[0, 100],
            labels={"vax_coverage": f"{current_vax} %"},
            template="plotly_white",
        )

        fig_map.update_layout(height=450, margin=dict(l=0, r=0, t=0, b=0))
        st.plotly_chart(fig_map, width="stretch")
    else:
        st.info("No regional data available for this selection.")

# 5. FOOTER
st.divider()
st.caption(
    f"Data Source: WHO Global Health Observatory. Analyzing {selected_disease} impact via {current_vax} coverage."
)
