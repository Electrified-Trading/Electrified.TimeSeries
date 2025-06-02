namespace Electrified.TimeSeries;

/// <summary>
/// A read-only record representing a price candle/bar with financial data.
/// </summary>
/// <typeparam name="T">The type of data contained in the bar</typeparam>
public record Bar<T> : IComparable<Bar<T>>
{
	/// <summary>
	/// Gets the timestamp of the bar.
	/// </summary>
	public required DateTime Timestamp { get; init; }

	/// <summary>
	/// Gets the financial data of the bar.
	/// </summary>
	public required T Data { get; init; }	/// <summary>
	/// Gets the trading volume of the bar.
	/// </summary>
	public required decimal Volume { get; init; }

	/// <summary>
	/// Compares the current bar with another bar.
	/// </summary>
	/// <param name="other">The bar to compare with</param>
	/// <returns>
	/// A value indicating the relative ordering of the bars:
	/// Less than zero: This instance precedes other.
	/// Zero: This instance is equal to other.
	/// Greater than zero: This instance follows other.
	/// </returns>
	public int CompareTo(Bar<T>? other)
	{
		// First compare by Timestamp.
		if (other is null) return 1; // Null is less than any other value
		int result = Timestamp.CompareTo(other.Timestamp);
		if (result != 0) return result; // If not equal, return the comparison result

		// If the data is comparable, then compare the data as well.
		if (Data is IComparable<T> comparableData)
		{
			result = comparableData.CompareTo(other.Data);
			if (result != 0) return result; // If not equal, return the comparison result
		}

		// Check if data is equal.
		if (Data is IEquatable<T> equatableData && !equatableData.Equals(other.Data))
			// Impossible to compare, so throw.
			throw new InvalidOperationException("Data is not comparable.");

		// Lastly, compare the volume.
		return Volume.CompareTo(other.Volume);
	}
}

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
