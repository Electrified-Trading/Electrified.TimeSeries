using Microsoft.Extensions.Primitives;
using System.Collections;

namespace Electrified.TimeSeries;

/// <summary>
/// A read-only record representing OHLC (Open, High, Low, Close) data.
/// </summary>
public readonly record struct OHLC
	: IEnumerable<KeyValuePair<string, decimal>>,
	  IEnumerable<KeyValuePair<string, object>>,
	  IParseFields<OHLC>,
	  IHaveFieldNames
{
	/// <summary>
	/// Gets or sets the opening price.
	/// </summary>
	public required decimal Open { get; init; }

	/// <summary>
	/// Gets or sets the highest price during the period.
	/// </summary>
	public required decimal High { get; init; }

	/// <summary>
	/// Gets or sets the lowest price during the period.
	/// </summary>
	public required decimal Low { get; init; }

	/// <summary>
	/// Gets or sets the closing price.
	/// </summary>
	public required decimal Close { get; init; }

	/// <summary>
	/// Gets the collection of field names for OHLC data.
	/// </summary>
	public static IReadOnlyList<string> FieldNames { get; }
		= [nameof(Open), nameof(High), nameof(Low), nameof(Close)];

	/// <summary>
	/// Returns an enumerator that iterates through the OHLC values as key-value pairs.
	/// </summary>
	/// <returns>An enumerator for the OHLC data</returns>
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

	/// <summary>
	/// Parses OHLC data from a collection of field-value pairs.
	/// </summary>
	/// <param name="fields">The collection of field name and value pairs containing OHLC data</param>
	/// <returns>A new OHLC instance parsed from the fields</returns>
	/// <exception cref="ArgumentException">Thrown when required OHLC fields are missing or have invalid format</exception>
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