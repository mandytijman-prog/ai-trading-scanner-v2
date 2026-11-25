# SamenBot – eerste gezamenlijke MT5-demo prototype

Deze versie is **nieuw vanaf nul**. Mandy's scanner en GitHub-repository worden niet gebruikt of aangepast.

## Belangrijke beperkingen
- Demo-only: de EA weigert orders op echte accounts.
- Standaard staat `EnableDemoOrders=false`. Hij logt dan uitsluitend signalen.
- Strategie: M15, EMA20/EMA50, pullback rond EMA20 en bevestiging bij gesloten candle; ATR-stop en 1:2 doel.
- `RiskPerTradeEUR=10` en `DailyLossLimitEUR=30` zijn **ontwerpinstellingen**, geen gegarandeerde verlieslimieten.
- De daglimiet begint opnieuw bij EA-start / brokerdag en rekent NIET alle FTMO-dagverliesregels of reeds afgesloten eerdere trades mee. Gebruik dit prototype daarom niet om te bewijzen dat je aan een FTMO-challenge voldoet.
- Houd rekening met spread, commissie, slippage, symbolen met suffix, broker-specificaties, nieuws en handelsstops.
- Er is geen bewijs van winstgevendheid of garantie dat orders altijd worden uitgevoerd. De EA is niet in een echte MT5-terminal gecompileerd of gebacktest.
- Er is nog geen 24/7 hosting of gedeeld dashboard.

## Installatie via Windows / MT5
1. Open MetaTrader 5 met uitsluitend een **demoaccount**.
2. Open MT5 > Tools > MetaQuotes Language Editor (F4).
3. Maak een nieuwe Expert Advisor, of zet `SamenBot_Demo_v1.mq5` onder `MQL5/Experts/`.
4. Open in MetaEditor en druk F7 voor compileren. Herstel eventuele compilerwaarschuwingen vóór gebruik.
5. Open de **Strategy Tester** in MT5 (Ctrl+R), selecteer XAUUSD (controleer exacte symboolnaam) en M15, en backtest minstens twee jaar met 'Every tick based on real ticks' waar beschikbaar.
6. Laat `EnableDemoOrders=false` voor de eerste tests. Bekijk logs in Experts/Journal.
7. Test eventuele demo-orders pas na review van resultaten en code. Zet `EnableDemoOrders=true` alleen op de demoomgeving.

## Gezamenlijk testen
- Gebruik één gedeelde private GitHub-repository, met verschillende branches, pull requests en vastgelegde testresultaten.
- Gebruik ieders eigen demoaccount. Deel nooit FTMO-logins, API-secrets of wachtwoorden.
- Sla testresultaten op met datum, tijdzone, symbol, spread, periode, versie, P&L, winrate en max drawdown.
- Leg vóór betaalde challenges apart vast wie code bezit, wie kosten betaalt en hoe eventuele opbrengsten legaal verdeeld kunnen worden.

## Vervolgontwikkeling vóór autonoom gebruik
1. Onafhankelijke prop-firm risicomodule met persistente equity-/tradehistorie, reset op juiste FTMO-daggrens, floating P&L en accountbrede limieten.
2. Betrouwbare orderstatus, herstart-/disconnectdetectie, noodstop en max aantal trades.
3. Unit- en integratietests, backtests out-of-sample en forward demo tests.
4. Hostkeuze (VPS) afgestemd op FTMO-toestemming, monitoring en alarmering.
