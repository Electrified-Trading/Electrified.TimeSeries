namespace Electrified.TimeSeries;

/// <summary>
/// Represents a time interval for bar/candle aggregation with unit and length components.
/// </summary>
public readonly partial record struct BarInterval
{
	/// <summary>
	/// Initializes a new instance of the <see cref="BarInterval"/> struct.
	/// </summary>
	/// <param name="unit">The unit of time for the interval</param>
	/// <param name="length">The number of units for the interval (default: 1)</param>
	public BarInterval(IntervalUnit unit, ushort length = 1)
	{
		Unit = unit;
		Length = length;
	}

	/// <summary>
	/// Gets the unit of time for this interval.
	/// </summary>
	public IntervalUnit Unit { get; }

	/// <summary>
	/// Gets the number of units for this interval.
	/// </summary>
	public ushort Length { get; }

	/// <summary>
	/// Gets the total time span represented by this interval.
	/// </summary>
	public TimeSpan Interval
		=> TimeSpan.FromMilliseconds(Length * (uint)Unit);

	/// <summary>
	/// Creates a second-based interval.
	/// </summary>
	/// <param name="length">The number of seconds (default: 1)</param>
	/// <returns>A new BarInterval representing the specified number of seconds</returns>
	public static BarInterval Second(ushort length = 1)
		=> new(IntervalUnit.Second, length);

	/// <summary>
	/// Creates a minute-based interval.
	/// </summary>
	/// <param name="length">The number of minutes (default: 1)</param>
	/// <returns>A new BarInterval representing the specified number of minutes</returns>
	public static BarInterval Minute(ushort length = 1)
		=> new(IntervalUnit.Minute, length);

	/// <summary>
	/// Creates an hour-based interval.
	/// </summary>
	/// <param name="length">The number of hours (default: 1)</param>
	/// <returns>A new BarInterval representing the specified number of hours</returns>
	public static BarInterval Hour(ushort length = 1)
		=> new(IntervalUnit.Hour, length);

	/// <summary>
	/// Creates a day-based interval.
	/// </summary>
	/// <param name="length">The number of days (default: 1)</param>
	/// <returns>A new BarInterval representing the specified number of days</returns>
	public static BarInterval Day(ushort length = 1)
		=> new(IntervalUnit.Day, length);

	/// <summary>
	/// Creates a week-based interval.
	/// </summary>
	/// <param name="length">The number of weeks (default: 1)</param>
	/// <returns>A new BarInterval representing the specified number of weeks</returns>
	public static BarInterval Week(ushort length = 1)
		=> new(IntervalUnit.Week, length);
}