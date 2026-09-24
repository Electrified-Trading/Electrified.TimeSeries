namespace Electrified.TimeSeries;

/// <summary>
/// Represents stock price data
/// </summary>
public record StockData<T>
{
	/// <summary>
	/// The stock symbol
	/// </summary>
	public required string Symbol { get; init; }

	/// <summary>
	/// The frequency of the data (daily, weekly, etc.)
	/// </summary>
	public required Timeframe Timeframe { get; init; }

	/// <summary>
	/// Collection of price bars
	/// </summary>
	public required IReadOnlyList<Bar<T>> Bars { get; init; }
}