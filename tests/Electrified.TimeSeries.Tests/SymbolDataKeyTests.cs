namespace Electrified.TimeSeries.Tests;

public class SymbolDataKeyTests
{
	[Fact]
	public void GetBlocks_MultiYearRange_YieldsOneDistinctBlockPerYear()
	{
		var range = new DateRange(new DateOnly(2020, 1, 1), new DateOnly(2022, 12, 31));
		var key = new SymbolDataKey("AMEX:SPY", Timeframe.Daily, range);

		var blocks = key.GetBlocks().Select(b => b.Range).ToList();

		Assert.Equal(
		[
			DateRange.FromYear(2020),
			DateRange.FromYear(2021),
			DateRange.FromYear(2022),
		], blocks);
	}

	[Fact]
	public void GetBlocks_DailyTimeframe_YieldsOneBlockPerYear()
	{
		var range = new DateRange(new DateOnly(2024, 1, 1), new DateOnly(2025, 12, 31));
		var key = new SymbolDataKey("AMEX:SPY", Timeframe.Daily, range);

		var blocks = key.GetBlocks().Select(b => b.Range).ToList();

		Assert.Equal(
		[
			DateRange.FromYear(2024),
			DateRange.FromYear(2025),
		], blocks);
	}

	[Fact]
	public void GetBlocks_Minute5Timeframe_YieldsOneBlockPerMonth()
	{
		// A range that a year-block strategy would collapse into a single block,
		// since it never crosses a year boundary (2024).
		var range = new DateRange(new DateOnly(2024, 1, 1), new DateOnly(2024, 3, 31));
		var key = new SymbolDataKey("AMEX:SPY", Timeframe.Minute5, range);

		var blocks = key.GetBlocks().Select(b => b.Range).ToList();

		Assert.Equal(
		[
			new DateRange(new DateOnly(2024, 1, 1), new DateOnly(2024, 1, 31)),
			new DateRange(new DateOnly(2024, 2, 1), new DateOnly(2024, 2, 29)), // 2024 is a leap year
			new DateRange(new DateOnly(2024, 3, 1), new DateOnly(2024, 3, 31)),
		], blocks);
	}
}
