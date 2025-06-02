namespace Electrified.TimeSeries;
public interface ISymbolTimeframe
{
	string Symbol { get; }
	Timeframe Timeframe { get; }
}
