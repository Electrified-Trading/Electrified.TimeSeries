using Microsoft.Extensions.Primitives;
using System.Collections;

namespace Electrified.TimeSeries;

/// <summary>
/// A read-only record representing OHLC (Open, High, Low, Close) data.
/// </summary>
/// <param name="Open">The opening price</param>
/// <param name="High">The highest price during the period</param>
/// <param name="Low">The lowest price during the period</param>
/// <param name="Close">The closing price</param>
public readonly record struct OHLC
	: IEnumerable<KeyValuePair<string, decimal>>,
	  IEnumerable<KeyValuePair<string, object>>,
	  IParseFields<OHLC>,
	  IHaveFieldNames
{
	public required decimal Open { get; init; }
	public required decimal High { get; init; }
	public required decimal Low { get; init; }
	public required decimal Close { get; init; }

	public static IReadOnlyList<string> FieldNames { get; }
		= [nameof(Open), nameof(High), nameof(Low), nameof(Close)];

	public IEnumerator<KeyValuePair<string, decimal>> GetEnumerator()
	{
		yield return new KeyValuePair<string, decimal>(nameof(Open), Open);
		yield return new KeyValuePair<string, decimal>(nameof(High), High);
		yield return new KeyValuePair<string, decimal>(nameof(Low), Low);
		yield return new KeyValuePair<string, decimal>(nameof(Close), Close);
	}

	IEnumerator IEnumerable.GetEnumerator() => GetEnumerator();

	IEnumerator<KeyValuePair<string, object>> IEnumerable<KeyValuePair<string, object>>.GetEnumerator()
		=> GetEnumerator().AsObjects();

	public static OHLC ParseFields(IEnumerable<KeyValuePair<string, StringSegment>> fields)
	{
		try
		{
			var dict = fields.ToDictionary(kvp => kvp.Key, kvp => kvp.Value, StringComparer.OrdinalIgnoreCase);
			return new OHLC
			{
				Open = decimal.Parse(dict[nameof(Open)]),
				High = decimal.Parse(dict[nameof(High)]),
				Low = decimal.Parse(dict[nameof(Low)]),
				Close = decimal.Parse(dict[nameof(Close)]),
			};
		}
		catch (FormatException ex)
		{
			throw new ArgumentException("Invalid number format in OHLC data.", ex);
		}
		catch (KeyNotFoundException ex)
		{
			throw new ArgumentException($"Missing required OHLC field: {ex.Message}", ex);
		}
	}
}
