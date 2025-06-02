using Microsoft.Extensions.Primitives;

namespace Electrified.TimeSeries;
public interface IParseFields<T>
{
	static abstract T ParseFields(IEnumerable<KeyValuePair<string, StringSegment>> fields);
}
