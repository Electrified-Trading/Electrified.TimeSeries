using Microsoft.Extensions.Primitives;

namespace Electrified.TimeSeries;

/// <summary>
/// Defines a contract for types that can be parsed from field-value pairs.
/// </summary>
/// <typeparam name="T">The type that can be parsed from fields</typeparam>
public interface IParseFields<T>
{
	/// <summary>
	/// Parses an instance of type T from a collection of field-value pairs.
	/// </summary>
	/// <param name="fields">The collection of field name and value pairs</param>
	/// <returns>An instance of type T parsed from the fields</returns>
	/// <exception cref="ArgumentException">Thrown when required fields are missing or invalid</exception>
	/// <exception cref="FormatException">Thrown when field values cannot be parsed</exception>
	static abstract T ParseFields(IEnumerable<KeyValuePair<string, StringSegment>> fields);
}