namespace Electrified.TimeSeries;
public interface IHaveFieldNames
{
	static abstract IReadOnlyList<string> FieldNames { get; }
}
