namespace Electrified.TimeSeries;

/// <summary>
/// Defines time interval units as millisecond multipliers for precise time calculations.
/// </summary>
public enum IntervalUnit : uint
{
	/// <summary>
	/// One millisecond (1 ms).
	/// </summary>
	Millisecond = 1,

	/// <summary>
	/// One second (1,000 ms).
	/// </summary>
	Second = 1000 * Millisecond,

	/// <summary>
	/// One minute (60,000 ms).
	/// </summary>
	Minute = 60 * Second,

	/// <summary>
	/// One hour (3,600,000 ms).
	/// </summary>
	Hour = 60 * Minute,

	/// <summary>
	/// One day (86,400,000 ms).
	/// </summary>
	Day = 24 * Hour,

	/// <summary>
	/// One week (604,800,000 ms).
	/// </summary>
	Week = 7 * Day,

	// Month or year are too arbitrary to define as fixed intervals.
}