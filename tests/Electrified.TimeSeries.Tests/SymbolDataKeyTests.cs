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
}
