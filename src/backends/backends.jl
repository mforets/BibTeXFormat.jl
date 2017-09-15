export write_to_stream,
       write_to_file,
       write_to_string,
       render_as
"""This is the base class for the backends. We encourage
you to implement as many of the symbols and tags as
possible when you create a new plugin.

symbols[u'ndash']    : Used to separate pages
symbols[u'newblock'] : Used to separate entries in the bibliography
symbols[u'nbsp']     : A non-breakable space

tags[u'em']          : emphasize text
tags[u'strong']      : emphasize text even more
tags[u'i']           : italicize text, not semantic
tags[u'b']           : embolden text, not semantic
tags[u'tt']          : typewrite text, not semantic
"""
abstract type BaseBackend end

const symbols = Dict{Type,Dict{String,String}}()
const tags    = Dict{Type,Dict{String,String}}()
const default_suffix = Dict{Type,String}()

function write_prologue(self::BaseBackend, s)
end
function write_epilogue(self::BaseBackend,s )
end
:"""Format the given string *str_*.
The default implementation simply returns the string ad verbatim.
Override this method for non-string backends.
"""
function format(self::T, str::String) where T<:BaseBackend
    return str
end

function format(self::T, r::RichText, t) where T<:BaseBackend
    return convert(String,t)
end

"""Format a "protected" piece of text.

In LaTeX backend, it is formatted as a {braced group}.
Most other backends would just output the text as-is.
"""
function format(self::T, t::Protected, text) where T<:BaseBackend
	return t.text
end

"""Render a sequence of rendered Text objects.
The default implementation simply concatenates
the strings in rendered_list.
Override this method for non-string backends.
"""
function render_sequence(self::T, rendered_list) where T <:BaseBackend
	return Base.join(rendered_list, "")
end

function write_entry()
end

function  write_to_file(self, formatted_entries, filename)
    file = open(filename, "w")
    write_to_stream(self, formatted_entries, file)
    close(file)
end
function write_to_string(self, formatted_entries)
    local buff = IOBuffer()
    write_to_stream(self, formatted_entries, buff)
    return String(buff)
end
function write_to_stream(self::BaseBackend, formatted_bibliography, stream=IOBuffer())

    write_prologue(self, stream)
    for (key, text, label ) in formatted_bibliography
        write_entry(self,stream, key, label,  render(text,self))
	end
	write_epilogue(self,stream)
    return stream
end
    #include("Markdown.jl")

function find_backend(t::String)
    t  = lowercase(t)
    if t=="html"
        return HTMLBackend
    elseif t=="latex"
        return LaTeXBackend
    elseif t=="text"
        return TextBackend
    elseif t=="markdown"
        return MarkdownBackend
    end
end

"""
Render this :py:class:`Text` into markup.
This is a wrapper method that loads a formatting backend plugin
and calls :py:meth:`Text.render`.

>>> text = Text("Longcat is ", Tag("em", "looooooong"), "!")
>>> print(text.render_as("html"))
Longcat is <em>looooooong</em>!
>>> print(text.render_as("latex"))
Longcat is \emph{looooooong}!
>>> print(text.render_as("text"))
Longcat is looooooong!

:param backend_name: The name of the output backend (like ``"latex"`` or
	``"html"``).

"""

function render_as(self::T, backend_name) where T<:BaseText
	backend_cls = find_backend(backend_name)
	return render(self,backend_cls())
end
function render_multipart(self::T, backend) where T<:MultiPartText
    local rendered_list = [render(part,backend) for part in self.parts]
    local text =  render_sequence(backend,rendered_list)
	return format(backend,self, text)
end
function render(self::T, backend) where T<:MultiPartText
    return render_multipart(self,backend)
end

function render(self::RichString, backend)
    return format(backend,self.value)
end

function  render(self::Protected, backend)
    text = render_multipart(self,backend)
    return format(backend,self, text)
end

function render(self::TextSymbol, backend)
    return typeof(backend).name.module.symbols[self.name]
end
include("html.jl")
include("latex.jl")
include("markdown.jl")
include("plaintext.jl")