defmodule Surface.FormatterTest do
  use ExUnit.Case

  alias Surface.Formatter

  def assert_formatter_outputs(input_code, expected_formatted_result, opts \\ []) do
    assert Formatter.format_string!(input_code, opts) == expected_formatted_result
  end

  def assert_formatter_doesnt_change(code, opts \\ []) do
    assert_formatter_outputs(code, code, opts)
  end

  test "children are indented 1 from parents" do
    assert_formatter_outputs(
      """
      <div>
      <ul>
      <li>
      <a>
      Hello
      </a>
      </li>
      </ul>
      </div>
      """,
      """
      <div>
        <ul>
          <li>
            <a>
              Hello
            </a>
          </li>
        </ul>
      </div>
      """
    )
  end

  test "Surface brackets for Elixir code still include the original code snippet" do
    assert_formatter_outputs(
      """
          <div :if = {{1 + 1      }}>
      {{"hello "<>"dolly"}}
      </div>




      """,
      """
      <div :if={{ 1 + 1 }}>
        {{ "hello " <> "dolly" }}
      </div>
      """
    )
  end

  test "Contents of Macro Components are preserved" do
    assert_formatter_doesnt_change("""
    <#MacroComponent>
    * One
    * Two
    ** Three
    *** Four
            **** Five
      -- Once I caught a fish alive
    </#MacroComponent>
    """)

    assert_formatter_doesnt_change("""
    <#MacroComponent>
     * One
     * Two
     ** Three
     *** Four
             **** Five
       -- Once I caught a fish alive
    </#MacroComponent>
    """)
  end

  test "Self closing Macro Components are preserved" do
    assert_formatter_doesnt_change("""
    <#MacroComponent />
    """)
  end

  test "lack of whitespace is preserved" do
    assert_formatter_outputs(
      """
      <div>
      <dt>{{ @tldr }}/{{ @question }}</dt>
      <dd><slot /></dd>
      </div>
      """,
      """
      <div>
        <dt>{{ @tldr }}/{{ @question }}</dt>
        <dd><slot /></dd>
      </div>
      """
    )
  end

  test "shorthand surface syntax is formatted by Elixir code formatter" do
    assert_formatter_outputs(
      "<div class={{ foo:        bar }}></div>",
      "<div class={{ foo: bar }} />\n"
    )
  end

  test "interpolation in attributes is formatted as expected" do
    assert_formatter_outputs(
      """
      <div class={{[1, 2, 3]}} />
      """,
      """
      <div class={{ [1, 2, 3] }} />
      """
    )

    assert_formatter_outputs(
      """
      <div class={{foo: "foofoofoofoofoofoofoofoofoofoo", bar: "barbarbarbarbarbarbarbarbarbarbar", baz: "bazbazbazbazbazbazbazbaz"}} />
      """,
      """
      <div class={{
        foo: "foofoofoofoofoofoofoofoofoofoo",
        bar: "barbarbarbarbarbarbarbarbarbarbar",
        baz: "bazbazbazbazbazbazbazbaz"
      }} />
      """
    )
  end

  test "interpolation in attributes of deeply nested elements" do
    assert_formatter_outputs(
      """
      <section>
      <div>
      <p class={{["foofoofoofoofoofoofoofoofoofoo", "barbarbarbarbarbarbarbarbarbarbar", "bazbazbazbazbazbazbazbaz"]}} />
      </div>
      </section>
      """,
      """
      <section>
        <div>
          <p class={{[
            "foofoofoofoofoofoofoofoofoofoo",
            "barbarbarbarbarbarbarbarbarbarbar",
            "bazbazbazbazbazbazbazbaz"
          ]}} />
        </div>
      </section>
      """
    )
  end

  test "interpolation in string attributes" do
    # Note that the formatter does not remove the extra whitespace at the end of the string.
    # We have no context about whether the whitespace in the given attribute is significant,
    # so we might break code by modifying it. Therefore, the contents of string attributes
    # are left alone other than formatting interpolated expressions.
    assert_formatter_outputs(
      """
      <Component foo="bar {{@baz}}  "></Component>
      """,
      """
      <Component foo="bar {{ @baz }}  " />
      """
    )
  end

  test "boolean, integer, and string literals in attributes are not wrapped in Surface brackets" do
    assert_formatter_outputs(
      """
      <Component true_prop={{ true }} false_prop={{ false }}
      int_prop={{12345}} str_prop={{ "some_string_value" }} />
      """,
      """
      <Component true_prop false_prop=false int_prop=12345 str_prop="some_string_value" />
      """
    )
  end

  test "float literals are kept in Surface brackets (because it doesn't work not to)" do
    assert_formatter_outputs(
      """
      <Component float_prop={{123.456}} />
      """,
      """
      <Component float_prop={{ 123.456 }} />
      """
    )
  end

  test "numbers are formatted with underscores per the Elixir formatter" do
    assert_formatter_outputs(
      """
      <Component int_prop={{1000000000}} float_prop={{123456789.123456789 }} />
      """,
      """
      <Component int_prop=1_000_000_000 float_prop={{ 123_456_789.123456789 }} />
      """
    )
  end

  test "attributes wrap at 98 characters by default" do
    assert_formatter_doesnt_change("""
    <Component foo="..........." bar="..............." baz="............" qux="..................." />
    """)

    assert_formatter_outputs(
      """
      <Component foo="..........." bar="..............." baz="............" qux="...................." />
      """,
      """
      <Component
        foo="..........."
        bar="..............."
        baz="............"
        qux="...................."
      />
      """
    )
  end

  test "attribute wrapping can be configured by :line_length in opts" do
    assert_formatter_outputs(
      """
      <Foo bar="bar" baz="baz"/>
      """,
      """
      <Foo
        bar="bar"
        baz="baz"
      />
      """,
      line_length: 20
    )
  end

  test "a single attribute always begins on the same line as the opening tag" do
    # Wrap in another element to help test whether indentation is working properly

    assert_formatter_outputs(
      """
      <p>
      <Foo bio={{%{age: 23, name: "John Jacob Jingleheimerschmidt", title: "Lead rockstar 10x ninja brogrammer", reports_to: "James Jacob Jingleheimerschmidt"}}}/>
      </p>
      """,
      """
      <p>
        <Foo bio={{%{
          age: 23,
          name: "John Jacob Jingleheimerschmidt",
          title: "Lead rockstar 10x ninja brogrammer",
          reports_to: "James Jacob Jingleheimerschmidt"
        }}} />
      </p>
      """
    )

    assert_formatter_outputs(
      """
      <p>
        <Foo urls={{["https://hexdocs.pm/elixir/DateTime.html#content", "https://hexdocs.pm/elixir/Exception.html#content"]}}/>
      </p>
      """,
      """
      <p>
        <Foo urls={{[
          "https://hexdocs.pm/elixir/DateTime.html#content",
          "https://hexdocs.pm/elixir/Exception.html#content"
        ]}} />
      </p>
      """
    )

    assert_formatter_outputs(
      """
      <p>
      <Foo bar={{baz: "BAZ", qux: "QUX", long: "LONG", longer: "LONGER", longest: "LONGEST", wrapping: "WRAPPING", next_line: "NEXT_LINE"}} />
      </p>
      """,
      """
      <p>
        <Foo bar={{
          baz: "BAZ",
          qux: "QUX",
          long: "LONG",
          longer: "LONGER",
          longest: "LONGEST",
          wrapping: "WRAPPING",
          next_line: "NEXT_LINE"
        }} />
      </p>
      """
    )

    assert_formatter_outputs(
      """
      <p>
      <Foo bar="A really really really really really really long string that makes this line longer than the default 98 characters"/>
      </p>
      """,
      """
      <p>
        <Foo bar="A really really really really really really long string that makes this line longer than the default 98 characters" />
      </p>
      """
    )
  end

  test "(bugfix) a trailing interpolation does not get an extra newline added" do
    assert_formatter_doesnt_change("""
    <p>Foo</p><p>Bar</p>{{ baz }}
    """)
  end

  test "Contents of <pre> and <code> tags aren't formatted" do
    # Note that the output looks pretty messy, but it's because
    # we're retaining 100% of the exact characters between the
    # <pre> and </pre> tags, etc.
    assert_formatter_outputs(
      """
      <p>
      <pre>
          Four
       One
               Nine
      </pre> </p> <div> <code>Some code
      goes    here   </code> </div>
      """,
      """
      <p>
        <pre>
          Four
       One
               Nine
      </pre>
      </p>
      <div>
        <code>Some code
      goes    here   </code>
      </div>
      """
    )
  end

  test "<pre>, <code>, and <#MacroComponent> tags can contain interpolations or components, but the string portions are untouched" do
    # Note that the output looks pretty messy, but it's because
    # we're retaining 100% of the exact characters between the
    # <pre> and </pre> tags, etc.
    #
    # Also, note that the _opening_ tags are consistently at the same
    # indentation level because those tags are not inside a context
    # in which we render children verbatim. (In other words, there's
    # no risk of changing browser behavior.)
    assert_formatter_outputs(
      """
      <pre>
      {{   @data   }}
            <Component />
      </pre>
          <code>
        {{ @data }}
        <Component />
          </code>


            <#MacroComponent> Foo {{@bar}} baz </#MacroComponent>
      """,
      """
      <pre>
      {{ @data }}
            <Component />
      </pre>
      <code>
        {{ @data }}
        <Component />
          </code>

      <#MacroComponent> Foo {{@bar}} baz </#MacroComponent>
      """
    )
  end

  test "HTML elements rendered in <pre>/<code>/<#MacroComponent> tags are left in their original state" do
    # Note that the <code> and <#Macro> components (which are too indented)
    # are brought all the way to the left side, but all of the whitespace
    # characters therein are left alone.
    assert_formatter_outputs(
      """
      <pre>
          <div>    <p>  Hello world  </p>  </div>
        </pre>

        <code>
            <div>    <p>  Hello world  </p>  </div>
          </code>

          <#Macro>
              <div>    <p>  Hello world  </p>  </div>
            </#Macro>
      """,
      """
      <pre>
          <div>    <p>  Hello world  </p>  </div>
        </pre>

      <code>
            <div>    <p>  Hello world  </p>  </div>
          </code>

      <#Macro>
              <div>    <p>  Hello world  </p>  </div>
            </#Macro>
      """
    )
  end

  test "Attributes are lines up properly when split onto newlines with a multi-line attribute" do
    assert_formatter_outputs(
      """
      <Parent>
        <Child
          first=123
          second={{[
                  {"foo", application.description},
                  {"baz", application.product_owner}
                ]}}
        />
      </Parent>
      """,
      """
      <Parent>
        <Child
          first=123
          second={{[
            {"foo", application.description},
            {"baz", application.product_owner}
          ]}}
        />
      </Parent>
      """
    )
  end

  test "If any attribute is formatted with a newline, attributes are split onto separate lines" do
    # This is because multiple of them may have newlines, and it could result in odd formatting such as:
    #
    # <Foo bar=1 baz={{[
    #   "bazz",
    #   "bazz",
    #   "bazz"
    # ]}} qux=false />
    #
    # The attributes aren't the easiest to read in that case, and we're making the choice not
    # to open the can of worms of potentially re-ordering attributes, because that introduces
    # plenty of complexity and might not be desired by users.
    assert_formatter_outputs(
      """
      <Parent>
        <Child
          first=123
          second={{[
                  {"foo", foo},
                  {"bar", bar}
                ]}}
        />
      </Parent>
      """,
      """
      <Parent>
        <Child
          first=123
          second={{[
            {"foo", foo},
            {"bar", bar}
          ]}}
        />
      </Parent>
      """
    )

    assert_formatter_outputs(
      """
      <Parent>
        <Child first={{[
        {"foo", foo}, {"bar", bar}
        ]}} second=123 />
      </Parent>
      """,
      """
      <Parent>
        <Child
          first={{[
            {"foo", foo},
            {"bar", bar}
          ]}}
          second=123
        />
      </Parent>
      """
    )
  end

  test "tags without children are collapsed if there is no whitespace between them" do
    assert_formatter_outputs(
      """
      <Foo></Foo>
      """,
      """
      <Foo />
      """
    )

    # Should these be collapsed?
    assert_formatter_doesnt_change("""
    <Foo> </Foo>
    """)
  end

  test "interpolated lists in attributes with invisible brackets are formatted" do
    assert_formatter_outputs(
      ~S"""
      <Component foo={{ "bar", 1, @a_very_long_name_in_assigns <> @another_extremely_long_name_to_make_the_elixir_formatter_wrap_this_expression }} />
      """,
      ~S"""
      <Component foo={{
        "bar",
        1,
        @a_very_long_name_in_assigns <>
          @another_extremely_long_name_to_make_the_elixir_formatter_wrap_this_expression
      }} />
      """
    )
  end

  test "existing whitespace in string attributes is not altered when there are multiple attributes" do
    # The output may not look "clean", but it didn't look "clean" to begin with, and it's the only
    # way to ensure the formatter doesn't accidentally change the behavior of the resulting code.
    #
    # As with the Elixir formatter, it's important that the semantics of the code remain the same.
    assert_formatter_outputs(
      """
      <Component foo=false bar="a
        b
        c"
      />
      """,
      """
      <Component
        foo=false
        bar="a
        b
        c"
      />
      """
    )
  end

  test "existing whitespace in string attributes is not altered when there is only one attribute" do
    assert_formatter_doesnt_change("""
    <foo>
      <bar>
        <baz qux="one
        two" />
      </bar>
    </foo>
    """)
  end

  test "attributes that are a list merged with a keyword list are formatted" do
    assert_formatter_outputs(
      """
      <span class={{"container", "container--dark": @dark_mode}} />
      """,
      """
      <span class={{ "container", "container--dark": @dark_mode }} />
      """
    )
  end

  test "interpolated attributes with a function call that omits parentheses are formatted" do
    assert_formatter_outputs(
      """
      <Component items={{Enum.map @items, & &1.foo}}/>
      """,
      """
      <Component items={{ Enum.map(@items, & &1.foo) }} />
      """
    )
  end

  test "interpolations that line-wrap are indented properly" do
    assert_formatter_outputs(
      """
      <Component>
        {{ link "Log out", to: Routes.user_session_path(Endpoint, :delete), method: :delete, class: "container"}}
      </Component>
      """,
      """
      <Component>
        {{ link("Log out",
          to: Routes.user_session_path(Endpoint, :delete),
          method: :delete,
          class: "container"
        ) }}
      </Component>
      """
    )
  end

  test "a single extra newline between children is retained" do
    assert_formatter_doesnt_change("""
    <Component>
      foo

      bar
    </Component>
    """)
  end

  test "multiple extra newlines between children are collapsed to one" do
    assert_formatter_outputs(
      """
      <Component>
        foo



        bar
      </Component>
      """,
      """
      <Component>
        foo

        bar
      </Component>
      """
    )
  end

  test "at most one blank newline is retained when an HTML comment exists" do
    assert_formatter_outputs(
      ~S"""
      <div>
        <Component />

        <!-- Comment -->
        <AfterComment />
      </div>
      """,
      ~S"""
      <div>
        <Component />

        <AfterComment />
      </div>
      """
    )
  end

  test "an interpolation with only a code comment is formatted" do
    assert_formatter_outputs(
      """
      {{# Foo}}
      """,
      """
      {{ # Foo }}
      """
    )
  end

  test "indent option" do
    assert_formatter_outputs(
      """
      <p>
      <span>
      Indented
      </span>
      </p>
      """,
      """
            <p>
              <span>
                Indented
              </span>
            </p>
      """,
      indent: 3
    )
  end

  test "inline elements mixed with text are left on the same line by default" do
    assert_formatter_doesnt_change("""
    The <b>Dialog</b> is a stateless component. All event handlers
    had to be defined in the parent <b>LiveView</b>.
    """)

    assert_formatter_doesnt_change("""
    <strong>Surface</strong> <i>v{{ surface_version() }}</i> -
    <a href="http://github.com/msaraiva/surface">github.com/msaraiva/surface</a>.
    """)

    assert_formatter_doesnt_change("""
    This <b>Dialog</b> is a stateful component. Cool!
    """)

    assert_formatter_doesnt_change("""
    <Card>
      <Header>
        A simple card component
      </Header>

      This is the same Card component but now we're using
      <strong>typed slotables</strong> instead of <strong>templates</strong>.

      <Footer>
        <a href="#" class="card-footer-item">Footer Item 1</a>
        <a href="#" class="card-footer-item">Footer Item 2</a>
      </Footer>
    </Card>
    """)
  end

  test "when element content and tags aren't left on the same line, the next sibling is pushed to its own line" do
    assert_formatter_outputs(
      """
      <div> <div> Hello </div> {{1 + 1}} <p>Goodbye</p> </div>
      """,
      """
      <div>
        <div>
          Hello
        </div>
        {{ 1 + 1 }} <p>Goodbye</p>
      </div>
      """
    )

    assert_formatter_outputs(
      """
      <div> <p> <span>Hello</span> </p> {{1 + 1}} <p>Goodbye</p> </div>
      """,
      """
      <div>
        <p>
          <span>Hello</span>
        </p>
        {{ 1 + 1 }} <p>Goodbye</p>
      </div>
      """
    )
  end

  test "(bugfix) newlines aren't removed for no reason" do
    assert_formatter_doesnt_change("""
    <Test />

    Example 1
    <Test />

    Example 2

    <Test />
    """)
  end

  test "for docs" do
    assert_formatter_outputs(
      """
       <RootComponent with_many_attributes={{ true }} causing_this_line_to_wrap={{ true}} because_it_is_too_long={{ "yes, this line is long enough to wrap" }}>
         <!-- An HTML comment -->
         {{#An Elixir comment}}



         <div :if={{@show_div}}
         class="container">
             <p> Text inside paragraph    </p>
          <span>Text touching parent tags</span>
         </div>

      <Child  items={{[%{name: "Option 1", key: 1}, %{name: "Option 2", key:  2},    %{name: "Option 3", key: 3}, %{name: "Option 4", key: 4}]}}>
        Default slot contents
      </Child>
      </RootComponent>
      """,
      """
      <RootComponent
        with_many_attributes
        causing_this_line_to_wrap
        because_it_is_too_long="yes, this line is long enough to wrap"
      >
        {{ # An Elixir comment }}

        <div :if={{ @show_div }} class="container">
          <p>
            Text inside paragraph
          </p>
          <span>Text touching parent tags</span>
        </div>

        <Child items={{[
          %{name: "Option 1", key: 1},
          %{name: "Option 2", key: 2},
          %{name: "Option 3", key: 3},
          %{name: "Option 4", key: 4}
        ]}}>
          Default slot contents
        </Child>
      </RootComponent>
      """
    )

    assert_formatter_outputs(
      """
      <div> <p>Hello</p> </div>
      """,
      """
      <div>
        <p>Hello</p>
      </div>
      """
    )

    assert_formatter_outputs(
      """
      <p>Hello</p>





      <p>Goodbye</p>
      """,
      """
      <p>Hello</p>

      <p>Goodbye</p>
      """
    )

    assert_formatter_outputs(
      """
      <section>
        <p>Hello</p>
        <p>and</p>





        <p>Goodbye</p>
      </section>
      """,
      """
      <section>
        <p>Hello</p>
        <p>and</p>

        <p>Goodbye</p>
      </section>
      """
    )
  end

  test "(bugfix) magic keyword lists with interpolated string keys are correctly identified and don't crash" do
    assert_formatter_outputs(
      ~S"""
      <Component attr={{"a-#{@b}": c}} />
      """,
      ~S"""
      <Component attr={{ "a-#{@b}": c }} />
      """
    )
  end

  test "void elements do not have slash in single tag" do
    assert_formatter_outputs(
      """
      <area />
      <base />
      <br />
      <col />
      <hr />
      <img />
      <input />
      <link />
      <meta />
      <param />
      <command />
      <keygen />
      <source />
      """,
      """
      <area>
      <base>
      <br>
      <col>
      <hr>
      <img>
      <input>
      <link>
      <meta>
      <param>
      <command>
      <keygen>
      <source>
      """
    )
  end
end
