namespace Electrified.TimeSeries;

/// <summary>
/// Defines different timeframes for financial data aggregation.
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
	Minute = -1
}