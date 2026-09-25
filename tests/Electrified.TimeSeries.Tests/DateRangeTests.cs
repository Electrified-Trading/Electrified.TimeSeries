namespace Electrified.TimeSeries.Tests;

public class DateRangeTests
{
	[Fact]
	public void GetBlocks_WithDailyTimeframe_YieldsYearBlocks()
	{
		var range = new DateRange(new DateOnly(2023, 6, 1), new DateOnly(2025, 3, 15));

		var blocks = range.GetBlocks(Timeframe.Daily).ToList();

		Assert.Equal(
		[
			new DateRange(new DateOnly(2023, 6, 1), new DateOnly(2023, 12, 31)),
			DateRange.FromYear(2024),
			new DateRange(new DateOnly(2025, 1, 1), new DateOnly(2025, 3, 15)),
		], blocks);
	}

	[Fact]
	public void GetBlocks_WithMinute5Timeframe_YieldsMonthBlocksAcrossAYearBoundary()
	{
		var range = new DateRange(new DateOnly(2024, 11, 15), new DateOnly(2025, 1, 10));

		var blocks = range.GetBlocks(Timeframe.Minute5).ToList();

		Assert.Equal(
		[
			new DateRange(new DateOnly(2024, 11, 15), new DateOnly(2024, 11, 30)),
			new DateRange(new DateOnly(2024, 12, 1), new DateOnly(2024, 12, 31)),
			new DateRange(new DateOnly(2025, 1, 1), new DateOnly(2025, 1, 10)),
		], blocks);
	}

	[Theory]
	[InlineData(Timeframe.Minute)]
	[InlineData(Timeframe.Minute15)]
	[InlineData(Timeframe.Minute30)]
	[InlineData(Timeframe.Hour)]
	[InlineData(Timeframe.Hour4)]
	public void GetBlocks_WithAnyIntradayTimeframe_YieldsMonthBlocks(Timeframe timeframe)
	{
		var range = new DateRange(new DateOnly(2024, 2, 1), new DateOnly(2024, 3, 31));

		var blocks = range.GetBlocks(timeframe).ToList();

		Assert.Equal(
		[
			new DateRange(new DateOnly(2024, 2, 1), new DateOnly(2024, 2, 29)),
			new DateRange(new DateOnly(2024, 3, 1), new DateOnly(2024, 3, 31)),
		], blocks);
	}

	[Fact]
	public void GetBlocks_WithNoneTimeframe_Throws()
	{
		var range = DateRange.FromYear(2024);

		Assert.Throws<ArgumentOutOfRangeException>(() => range.GetBlocks(Timeframe.None).ToList());
	}
}
