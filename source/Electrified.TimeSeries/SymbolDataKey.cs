using System.Diagnostics;

namespace Electrified.TimeSeries;

/// <summary>
/// Represents a unique key for accessing symbol data, combining a symbol, timeframe, and date range.
/// </summary>
public readonly record struct SymbolDataKey : ISymbolTimeframe
{
	/// <summary>
	/// Initializes a new instance of the <see cref="SymbolDataKey"/> struct.
	/// </summary>
	/// <param name="symbol">The financial instrument symbol</param>
	/// <param name="timeFrame">The timeframe of the data</param>
	/// <param name="range">The date range of the data</param>
	/// <exception cref="ArgumentNullException">Thrown when symbol is null</exception>
	/// <exception cref="ArgumentException">Thrown when symbol is empty or whitespace</exception>
	/// <exception cref="ArgumentOutOfRangeException">Thrown when timeframe is None or range is default</exception>
	public SymbolDataKey(string symbol, Timeframe timeFrame, DateRange range)
	{
		Symbol = symbol ?? throw new ArgumentNullException(nameof(symbol));
		ArgumentException.ThrowIfNullOrWhiteSpace(symbol, nameof(symbol));

		Timeframe = timeFrame == Timeframe.None ? throw new ArgumentOutOfRangeException(nameof(timeFrame)) : timeFrame;
		if (range == default)
			throw new ArgumentOutOfRangeException(nameof(range), "Range cannot be default.");

		Range = range; // Set the Range property
		Key = $"{symbol}/{timeFrame}/{range}";
	}

	/// <summary>
	/// Initializes a new instance of the <see cref="SymbolDataKey"/> struct from a <see cref="SymbolTimeframe"/> and a date range.
	/// </summary>
	/// <param name="source">The symbol timeframe information</param>
	/// <param name="range">The date range of the data</param>
	public SymbolDataKey(SymbolTimeframe source, DateRange range)
		: this(source.Symbol, source.Timeframe, range) { }

	/// <summary>
	/// Gets the financial instrument symbol.
	/// </summary>
	public string Symbol { get; }

	/// <summary>
	/// Gets the date range of the data.
	/// </summary>
	public DateRange Range { get; }

	/// <summary>
	/// Gets the timeframe of the data.
	/// </summary>
	public Timeframe Timeframe { get; }

	/// <summary>
	/// Gets the string representation of the key in format "symbol/timeframe/range".
	/// </summary>
	public string Key { get; }

	/// <summary>
	/// Implicitly converts a tuple of symbol, timeframe, and range to a <see cref="SymbolDataKey"/>.
	/// </summary>
	/// <param name="source">The tuple containing symbol, timeframe, and range</param>
	public static implicit operator SymbolDataKey((string Symbol, Timeframe Timeframe, DateRange Range) source)
		=> new(source.Symbol, source.Timeframe, source.Range);

	/// <summary>
	/// Implicitly converts a tuple of symbol timeframe and range to a <see cref="SymbolDataKey"/>.
	/// </summary>
	/// <param name="source">The tuple containing symbol timeframe and range</param>
	public static implicit operator SymbolDataKey((SymbolTimeframe stf, DateRange Range) source)
		=> new(source.stf, source.Range);

	/// <summary>
	/// Implicitly converts a <see cref="SymbolDataKey"/> to its string representation.
	/// </summary>
	/// <param name="source">The source symbol data key</param>
	public static implicit operator string(SymbolDataKey source)
		=> source.Key;

	/// <summary>
	/// Implicitly converts a <see cref="SymbolDataKey"/> to a <see cref="DateRange"/>.
	/// </summary>
	/// <param name="source">The source symbol data key</param>
	public static implicit operator DateRange(SymbolDataKey source)
		=> source.Range;

	/// <summary>
	/// Returns the string representation of this key.
	/// </summary>
	/// <returns>The key as a string in format "symbol/timeframe/range"</returns>
	public override string ToString() => Key;

	/// <summary>
	/// Implicitly converts a <see cref="SymbolDataKey"/> to a <see cref="SymbolTimeframe"/>.
	/// </summary>
	/// <param name="source">The source symbol data key</param>
	public static implicit operator SymbolTimeframe(SymbolDataKey source)
		=> new(source.Symbol, source.Timeframe);

	/// <summary>
	/// Gets the blocks that make up this symbol data key's range.
	/// </summary>
	/// <returns>An enumerable of symbol data keys, where each represents a block of data</returns>
	public IEnumerable<SymbolDataKey> GetBlocks()
	{
		// For now, we assume that a block is full year.
		var e = Range.GetBlocks().GetEnumerator();
		if (!e.MoveNext()) throw new UnreachableException("Range.GetBlocks() returned no blocks, which is unexpected.");
		var block = e.Current;
		if (block == Range)
		{
			yield return this; // If the range is a single block, return it directly.
			yield break;
		}

		do { yield return new SymbolDataKey(Symbol, Timeframe, block); }
		while (e.MoveNext());
	}
}