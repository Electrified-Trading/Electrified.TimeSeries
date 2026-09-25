namespace Electrified.TimeSeries;

/// <summary>
/// Provides factory methods for creating Bar instances.
/// </summary>
public static class Bar
{
	/// <summary>
	/// Creates a new bar with the specified date time, data, and volume.
	/// </summary>
	/// <param name="dateTime">The date and time of the bar</param>
	/// <param name="data">The data of the bar</param>
	/// <param name="volume">The volume of the bar</param>
	/// <returns>A new bar instance</returns>
	public static Bar<T> Create<T>(DateTime dateTime, T data, long volume) => new()
	{
		Timestamp = dateTime,
		Data = data,
		Volume = volume,
	};
}