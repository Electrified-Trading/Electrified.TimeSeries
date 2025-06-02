namespace Electrified.TimeSeries;

public static partial class ModelExtensions
{
	public static IEnumerator<KeyValuePair<string, object>> AsObjects(this IEnumerator<KeyValuePair<string, decimal>> source)
	{
		while (source.MoveNext())
		{
			yield return new KeyValuePair<string, object>(source.Current.Key, source.Current.Value);
		}
	}
}
