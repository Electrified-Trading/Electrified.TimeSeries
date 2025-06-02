namespace Electrified.TimeSeries;

public readonly record struct SymbolTimeframe : ISymbolTimeframe
{
	public SymbolTimeframe(string symbol, Timeframe timeFrame)
	{
		Symbol = symbol ?? throw new ArgumentNullException(nameof(symbol));
		Timeframe = timeFrame == Timeframe.None ? throw new ArgumentOutOfRangeException(nameof(timeFrame)) : timeFrame;

		ArgumentException.ThrowIfNullOrWhiteSpace(symbol, nameof(symbol));
	}

	public string Symbol { get; }

	public Timeframe Timeframe { get; }

	public static implicit operator SymbolTimeframe((string Symbol, Timeframe Timeframe) source)
		=> new(source.Symbol, source.Timeframe);
}
