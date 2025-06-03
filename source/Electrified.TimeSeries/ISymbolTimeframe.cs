namespace Electrified.TimeSeries;

/// <summary>
/// Defines a contract for objects that contain symbol and timeframe information.
/// </summary>
public interface ISymbolTimeframe
{
	/// <summary>
	/// Gets the financial instrument symbol.
	/// </summary>
	string Symbol { get; }

	/// <summary>
	/// Gets the timeframe for the data.
	/// </summary>
	Timeframe Timeframe { get; }
}