namespace Electrified.TimeSeries;

/// <summary>
/// Defines different timeframes for financial data aggregation. Non-negative values are
/// whole days; negative values are intraday and count minutes (e.g. <see cref="Minute5"/>
/// is 5 minutes), the sign distinguishing the two families from a single integer.
/// </summary>
public enum Timeframe
{
	/// <summary>
	/// No timeframe specified.
	/// </summary>
	None = 0,

	/// <summary>
	/// Daily timeframe (1 day).
	/// </summary>
	Daily = 1,

	/// <summary>
	/// Weekly timeframe (7 days).
	/// </summary>
	Weekly = 7,

	/// <summary>
	/// Monthly timeframe (30 days).
	/// </summary>
	Monthly = 30,

	/// <summary>
	/// Annual timeframe (365 days).
	/// </summary>
	Annualy = 365,

	/// <summary>
	/// Minute timeframe.
	/// </summary>
	Minute = -1,

	/// <summary>
	/// 5-minute intraday timeframe.
	/// </summary>
	Minute5 = -5,

	/// <summary>
	/// 15-minute intraday timeframe.
	/// </summary>
	Minute15 = -15,

	/// <summary>
	/// 30-minute intraday timeframe.
	/// </summary>
	Minute30 = -30,

	/// <summary>
	/// Hourly intraday timeframe.
	/// </summary>
	Hour = -60,

	/// <summary>
	/// 4-hour intraday timeframe.
	/// </summary>
	Hour4 = -240
}