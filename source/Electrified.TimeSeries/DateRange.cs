namespace Electrified.TimeSeries;

/// <summary>
/// Represents a range of dates from a start date to an end date.
/// </summary>
public readonly record struct DateRange
{
	/// <summary>
	/// Initializes a new instance of the <see cref="DateRange"/> struct.
	/// </summary>
	/// <param name="start">The start date of the range</param>
	/// <param name="end">The end date of the range</param>
	/// <exception cref="ArgumentOutOfRangeException">Thrown when start date is after end date</exception>
	public DateRange(DateOnly start, DateOnly end)
	{
		if (start > end)
			throw new ArgumentOutOfRangeException(nameof(start), "Start date cannot be after end date.");

		Start = start;
		End = end;
	}

	/// <summary>
	/// Creates a date range that spans the entire specified year.
	/// </summary>
	/// <param name="year">The year to create a range for</param>
	/// <returns>A date range from January 1 to December 31 of the specified year</returns>
	public static DateRange FromYear(int year)
		=> new(new DateOnly(year, 1, 1), new DateOnly(year, 12, 31));

	/// <summary>
	/// Creates a date range that spans the entire year of the specified date.
	/// </summary>
	/// <param name="date">The date to extract the year from</param>
	/// <returns>A date range from January 1 to December 31 of the year of the specified date</returns>
	public static DateRange FromYear(DateOnly date)
		=> FromYear(date.Year);

	/// <summary>
	/// Gets the start date of the range.
	/// </summary>
	public DateOnly Start { get; }

	/// <summary>
	/// Gets the end date of the range.
	/// </summary>
	public DateOnly End { get; }

	/// <summary>
	/// Gets the blocks that make up this date range, where each block is a complete year or partial year.
	/// </summary>
	/// <returns>An enumerable of date ranges, one per year or partial year</returns>
	public IEnumerable<DateRange> GetBlocks()
	{

		var current = Start;
		var currentYear = Start.Year;

	loop:
		if (currentYear == End.Year)
		{
			yield return new(current, End);
			yield break;
		}

		yield return new(current, new(currentYear, 12, 31));

		currentYear++;
		current = new DateOnly(currentYear, 1, 1);
		goto loop;

	}

	/// <summary>
	/// Returns a string representation of the date range, with special handling for complete periods.
	/// <list type="bullet">
	/// <item>Full year: "2023" for Jan 1 to Dec 31</item>
	/// <item>Full month: "202301" for Jan 1 to Jan 31</item>
	/// <item>Full months: "202301-202303" for Jan 1 to March 31</item>
	/// <item>Other ranges: "20230101-20231231" (standard format)</item>
	/// </list>
	/// </summary>
	/// <returns>A string representation of the date range</returns>
	public override string ToString()
	{
		// Check if the range is a full year (Jan 1 to Dec 31 of same year)
		if (IsFullYear())
			return Start.Year.ToString();

		// Check if the range is a full month (first day to last day of same month and year)
		if (IsFullMonth())
			return $"{Start.Year}{Start.Month:D2}";

		// Check if the range represents multiple full months (first day of a month to last day of another month)
		if (IsFullMonthsRange())
			return $"{Start.Year}{Start.Month:D2}-{End.Year}{End.Month:D2}";

		// Default format for other date ranges
		return $"{Start:yyyyMMdd}-{End:yyyyMMdd}";
	}

	/// <summary>
	/// Determines if this date range represents a complete year.
	/// </summary>
	/// <returns>True if the range is from January 1 to December 31 of the same year, otherwise false</returns>
	public bool IsFullYear()
	{
		return Start.Year == End.Year &&
			   Start.Month == 1 && Start.Day == 1 &&
			   End.Month == 12 && End.Day == 31;
	}

	/// <summary>
	/// Determines if this date range represents a complete month.
	/// </summary>
	/// <returns>True if the range is from the first to the last day of a single month, otherwise false</returns>
	public bool IsFullMonth()
	{
		return Start.Year == End.Year &&
			   Start.Month == End.Month &&
			   Start.Day == 1 &&
			   End.Day == DateTime.DaysInMonth(End.Year, End.Month);
	}

	/// <summary>
	/// Determines if this date range represents multiple complete months.
	/// </summary>
	/// <returns>True if the range spans multiple complete months, otherwise false</returns>
	public bool IsFullMonthsRange()
	{
		return Start.Day == 1 &&
			   End.Day == DateTime.DaysInMonth(End.Year, End.Month) &&
			   !(Start.Year == End.Year && Start.Month == End.Month); // Not a single month
	}

	/// <summary>
	/// Implicitly converts a tuple of start and end dates to a <see cref="DateRange"/>.
	/// </summary>
	/// <param name="source">The tuple containing start and end dates</param>
	public static implicit operator DateRange((DateOnly Start, DateOnly End) source)
		=> new(source.Start, source.End);
}