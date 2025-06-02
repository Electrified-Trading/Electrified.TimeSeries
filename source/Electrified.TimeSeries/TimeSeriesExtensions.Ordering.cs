using Electrified.TimeSeries;
using System.Runtime.CompilerServices;

namespace AlphaHawk.Models;

public static partial class ModelExtensions
{
	public static IEnumerable<Bar<TData>> EnforceOrder<TData>(
		this IEnumerable<Bar<TData>> source,
		DateTime previousTimestamp)
	{
		foreach (var bar in source)
		{
			if (bar.Timestamp < previousTimestamp)
				throw new InvalidOperationException("Bars are not in chronological order.");
			if (bar.Timestamp == previousTimestamp)
				throw new InvalidOperationException("Duplicate timestamps found.");

			yield return bar;
			previousTimestamp = bar.Timestamp;
		}
	}

	public static IEnumerable<Bar<TData>> EnforceOrder<TData>(
		this IEnumerable<Bar<TData>> source)
		=> source.EnforceOrder(DateTime.MinValue);

	public static async IAsyncEnumerable<Bar<TData>> EnforceOrderAsync<TData, TBars>(
		this IAsyncEnumerable<TBars> source,
		DateTime previousTimestamp,
		[EnumeratorCancellation] CancellationToken cancellation = default)
		where TBars : IEnumerable<Bar<TData>>
	{
		if (cancellation.IsCancellationRequested)
			yield break;

		await foreach (var block in source)
		{
			foreach (var bar in block.EnforceOrder(previousTimestamp))
			{
				yield return bar;
				previousTimestamp = bar.Timestamp;
			}

			if (cancellation.IsCancellationRequested)
				yield break;
		}
	}
}
