
import streamlit as st
from datetime import datetime

st.set_page_config(
    page_title="AI Trading Scanner V2.0",
    page_icon="📈",
    layout="wide"
)

st.markdown("""
<style>
.block-container {padding-top: 2rem;}
h1 {color: #D6A84B;}
</style>
""", unsafe_allow_html=True)

st.title("📈 AI Trading Scanner V2.0")
st.caption("BrightFunded | Manual Trading Assistant")

st.warning(
    "MT5 brokerverbinding nog niet actief. "
    "Er worden geen futures-proxyprijzen gebruikt."
)

st.subheader("Marktoverzicht")

col1, col2 = st.columns(2)

with col1:
    st.metric("XAUUSD", "Wachten op MT5")
    st.caption("Goud – brokerprijs niet beschikbaar")

with col2:
    st.metric("XAGUSD", "Wachten op MT5")
    st.caption("Zilver – brokerprijs niet beschikbaar")

st.divider()

st.subheader("Technische analyse")

col1, col2 = st.columns(2)

with col1:
    st.markdown("### XAUUSD")
    st.info("Wachten op brokerdata")
    st.write("H1 trend: —")
    st.write("M15 signaal: —")
    st.write("RSI: —")
    st.write("MACD: —")
    st.write("ATR: —")

with col2:
    st.markdown("### XAGUSD")
    st.info("Wachten op brokerdata")
    st.write("H1 trend: —")
    st.write("M15 signaal: —")
    st.write("RSI: —")
    st.write("MACD: —")
    st.write("ATR: —")

st.divider()

st.subheader("Tradinginstellingen")

st.write("Handelswijze: Handmatig")
st.write("Prop firm: BrightFunded")
st.write("Orderuitvoering: Uitgeschakeld")
st.write("Futures-proxy: Uitgeschakeld")

st.warning(
    "BUY en SELL zijn nog niet beschikbaar. "
    "Eerst moet de echte MT5-verbinding worden getest."
)

st.caption(
    "Laatste dashboardupdate: "
    + datetime.now().strftime("%d-%m-%Y %H:%M:%S")
)

