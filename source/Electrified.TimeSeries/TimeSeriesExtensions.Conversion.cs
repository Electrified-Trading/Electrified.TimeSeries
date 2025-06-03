namespace Electrified.TimeSeries;

/// <summary>
/// Extension methods for converting between different enumerable types in time series data.
/// </summary>
public static partial class ModelExtensions
{
	/// <summary>
	/// Converts an enumerator of decimal key-value pairs to an enumerator of object key-value pairs.
	/// </summary>
	/// <param name="source">The source enumerator containing decimal values</param>
	/// <returns>An enumerator where decimal values are boxed as objects</returns>
	public static IEnumerator<KeyValuePair<string, object>> AsObjects(this IEnumerator<KeyValuePair<string, decimal>> source)
	{
		while (source.MoveNext())
		{
			yield return new KeyValuePair<string, object>(source.Current.Key, source.Current.Value);
		}
	}
}