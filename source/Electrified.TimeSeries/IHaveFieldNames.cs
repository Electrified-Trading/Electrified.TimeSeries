namespace Electrified.TimeSeries;

/// <summary>
/// Defines a contract for types that provide field names for their data structure.
/// </summary>
public interface IHaveFieldNames
{
	/// <summary>
	/// Gets the collection of field names for this type.
	/// </summary>
	static abstract IReadOnlyList<string> FieldNames { get; }
}