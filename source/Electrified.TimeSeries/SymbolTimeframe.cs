namespace Electrified.TimeSeries;

/// <summary>
/// Represents a symbol-timeframe combination for financial data identification.
/// </summary>
public readonly record struct SymbolTimeframe : ISymbolTimeframe
{
	/// <summary>
	/// Initializes a new instance of the <see cref="SymbolTimeframe"/> struct.
	/// </summary>
	/// <param name="symbol">The financial instrument symbol</param>
	/// <param name="timeFrame">The timeframe for the data</param>
	/// <exception cref="ArgumentNullException">Thrown when symbol is null</exception>
	/// <exception cref="ArgumentException">Thrown when symbol is empty or whitespace</exception>
	/// <exception cref="ArgumentOutOfRangeException">Thrown when timeframe is None</exception>
	public SymbolTimeframe(string symbol, Timeframe timeFrame)
	{
		Symbol = symbol ?? throw new ArgumentNullException(nameof(symbol));
		Timeframe = timeFrame == Timeframe.None ? throw new ArgumentOutOfRangeException(nameof(timeFrame)) : timeFrame;

		ArgumentException.ThrowIfNullOrWhiteSpace(symbol, nameof(symbol));
	}

	/// <summary>
	/// Gets the financial instrument symbol.
	/// </summary>
	public string Symbol { get; }

	/// <summary>
	/// Gets the timeframe for the data.
	/// </summary>
	public Timeframe Timeframe { get; }

	/// <summary>
	/// Implicitly converts a tuple containing symbol and timeframe to a <see cref="SymbolTimeframe"/>.
	/// </summary>
	/// <param name="source">The tuple containing symbol and timeframe</param>
	public static implicit operator SymbolTimeframe((string Symbol, Timeframe Timeframe) source)
		=> new(source.Symbol, source.Timeframe);
}