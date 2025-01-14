defmodule Surface.Formatter.Phase do
  @moduledoc """
  A phase implementing a single "rule" for formatting code. These work as middleware
  between `Surface.Compiler.Parser.parse` and `Surface.Formatter.Render.node/2`
  to modify node lists before they are rendered.

  Some phases rely on other phases; `@moduledoc`s should make this explicit.

  For reference, the formatter operates by running these phases in the following order:

    - `Surface.Formatter.Phases.TagWhitespace`
    - `Surface.Formatter.Phases.Newlines`
    - `Surface.Formatter.Phases.SpacesToNewlines`
    - `Surface.Formatter.Phases.Indent`
    - `Surface.Formatter.Phases.FinalNewline`
  """

  alias Surface.Formatter

  @doc "The function implementing the phase. Returns the given nodes with the transformation applied."
  @callback run(nodes :: [Formatter.formatter_node()]) :: [Formatter.formatter_node()]

  @typedoc "A node that takes a list of nodes and returns them back after applying a transformation"
  @type node_transformer :: (nodes -> nodes)

  @typedoc "A list of nodes"
  @type nodes :: [Formatter.formatter_node()]

  @doc """
  Given a list of nodes, find all "element" nodes (HTML elements or Surface components)
  and transform children of those nodes using the given function.

  Useful for recursing deeply through the entire tree of nodes.
  """
  @spec transform_element_children(nodes, node_transformer) :: nodes
  def transform_element_children(nodes, transform) do
    Enum.map(nodes, fn
      {tag, attributes, children, meta} ->
        {tag, attributes, transform.(children), meta}

      node ->
        node
    end)
  end
end
