using Electrified.TimeSeries;
using System.Runtime.CompilerServices;

namespace Electrified.TimeSeries;

/// <summary>
/// Extension methods for enforcing chronological ordering in time series data.
/// </summary>
public static partial class ModelExtensions
{
	/// <summary>
	/// Ensures bars are in chronological order and throws exceptions for invalid sequences.
	/// </summary>
	/// <typeparam name="TData">The type of data contained in the bars</typeparam>
	/// <param name="source">The source enumerable of bars</param>
	/// <param name="previousTimestamp">The timestamp that must precede all bars in the sequence</param>
	/// <returns>The validated sequence of bars</returns>
	/// <exception cref="InvalidOperationException">Thrown when bars are not in chronological order or contain duplicates</exception>
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

	/// <summary>
	/// Validates that a sequence of bars is in chronological order without enumeration side effects.
	/// </summary>
	/// <typeparam name="TData">The type of data contained in the bars</typeparam>
	/// <param name="source">The source enumerable of bars to validate</param>
	/// <returns>True if the sequence is properly ordered, false otherwise</returns>
	public static bool IsChronologicallyOrdered<TData>(this IEnumerable<Bar<TData>> source)
	{
		DateTime? lastTimestamp = null;

		foreach (var bar in source)
		{
			if (lastTimestamp.HasValue && bar.Timestamp <= lastTimestamp.Value)
				return false;

			lastTimestamp = bar.Timestamp;
		}

		return true;
	}
	/// <summary>
	/// Gets the time span between the first and last bars in a sequence.
	/// </summary>
	/// <typeparam name="TData">The type of data contained in the bars</typeparam>
	/// <param name="source">The source enumerable of bars</param>
	/// <returns>The time span of the sequence, or null if the sequence is empty</returns>
	public static TimeSpan? GetTimeSpan<TData>(this IEnumerable<Bar<TData>> source)
	{
		Bar<TData>? first = null;
		Bar<TData>? last = null;

		foreach (var bar in source)
		{
			first ??= bar;
			last = bar;
		}

		return first is not null && last is not null ? last.Timestamp - first.Timestamp : null;
	}

	/// <summary>
	/// Ensures bars are in chronological order, starting from DateTime.MinValue.
	/// </summary>
	/// <typeparam name="TData">The type of data contained in the bars</typeparam>
	/// <param name="source">The source enumerable of bars</param>
	/// <returns>The validated sequence of bars</returns>
	/// <exception cref="InvalidOperationException">Thrown when bars are not in chronological order or contain duplicates</exception>
	public static IEnumerable<Bar<TData>> EnforceOrder<TData>(
		this IEnumerable<Bar<TData>> source)
		=> source.EnforceOrder(DateTime.MinValue);

	/// <summary>
	/// Asynchronously ensures bars are in chronological order across batches.
	/// </summary>
	/// <typeparam name="TData">The type of data contained in the bars</typeparam>
	/// <typeparam name="TBars">The type of enumerable containing bars</typeparam>
	/// <param name="source">The source async enumerable of bar batches</param>
	/// <param name="previousTimestamp">The timestamp that must precede all bars in the sequence</param>
	/// <param name="cancellation">Cancellation token for the async operation</param>
	/// <returns>An async enumerable of validated bars</returns>
	/// <exception cref="InvalidOperationException">Thrown when bars are not in chronological order or contain duplicates</exception>
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