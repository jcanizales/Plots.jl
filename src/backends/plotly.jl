
# https://plot.ly/javascript/getting-started

# ---------------------------------------------------------------------------

function _create_plot(pkg::PlotlyPackage; kw...)
  d = Dict(kw)
  # TODO: create the window/canvas/context that is the plot within the backend (call it `o`)
  # TODO: initialize the plot... title, xlabel, bgcolor, etc
  Plot(nothing, pkg, 0, d, Dict[])
end


function _add_series(::PlotlyPackage, plt::Plot; kw...)
  d = Dict(kw)
  # TODO: add one series to the underlying package
  push!(plt.seriesargs, d)
  plt
end

function _add_annotations{X,Y,V}(plt::Plot{PlotlyPackage}, anns::AVec{@compat(Tuple{X,Y,V})})
  # set or add to the annotation_list
  if haskey(plt.plotargs, :annotation_list)
    append!(plt.plotargs[:annotation_list], anns)
  else
    plt.plotargs[:annotation_list] = anns
  end
end

# ----------------------------------------------------------------

function _before_update_plot(plt::Plot{PlotlyPackage})
end

# TODO: override this to update plot items (title, xlabel, etc) after creation
function _update_plot(plt::Plot{PlotlyPackage}, d::Dict)
end

function _update_plot_pos_size(plt::PlottingObject{PlotlyPackage}, d::Dict)
end

# ----------------------------------------------------------------

# accessors for x/y data

function Base.getindex(plt::Plot{PlotlyPackage}, i::Int)
  d = plt.seriesargs[i]
  d[:x], d[:y]
end

function Base.setindex!(plt::Plot{PlotlyPackage}, xy::Tuple, i::Integer)
  d = plt.seriesargs[i]
  d[:x], d[:y] = xy
  plt
end

# ----------------------------------------------------------------

function _create_subplot(subplt::Subplot{PlotlyPackage}, isbefore::Bool)
  # TODO: build the underlying Subplot object.  this is where you might layout the panes within a GUI window, for example
  true
end

function _expand_limits(lims, plt::Plot{PlotlyPackage}, isx::Bool)
  # TODO: call expand limits for each plot data
end

function _remove_axis(plt::Plot{PlotlyPackage}, isx::Bool)
  # TODO: if plot is inner subplot, might need to remove ticks or axis labels
end

# ----------------------------------------------------------------

# TODO:
# _plotDefaults[:yrightlabel]       = ""
# _plotDefaults[:xlims]             = :auto
# _plotDefaults[:ylims]             = :auto
# _plotDefaults[:xticks]            = :auto
# _plotDefaults[:yticks]            = :auto
# _plotDefaults[:xscale]            = :identity
# _plotDefaults[:yscale]            = :identity
# _plotDefaults[:xflip]             = false
# _plotDefaults[:yflip]             = false

function plotlyfont(font::Font)
  Dict(
      :family => font.family,
      :size   => round(Int, font.pointsize*1.4),
      :color  => webcolor(font.color),
    )
end

function get_annotation_dict(x, y, val::Union{AbstractString,Symbol})
  Dict(
      :text => val,
      :xref => "x",
      :x => x,
      :yref => "y",
      :y => y,
      :showarrow => false,
    )
end

function get_annotation_dict(x, y, ptxt::PlotText)
  merge(get_annotation_dict(x, y, ptxt.str), Dict(
      :font => plotlyfont(ptxt.font),
      :xanchor => ptxt.font.halign == :hcenter ? :center : ptxt.font.halign,
      :yanchor => ptxt.font.valign == :vcenter ? :middle : ptxt.font.valign,
      :rotation => ptxt.font.rotation,
    ))
end

function plotlyscale(scale::Symbol)
  if scale == :log
    "log"
  else
    "-"
  end
end

use_axis_field(ticks) = !(ticks in (nothing, :none))

function get_plot_json(plt::Plot{PlotlyPackage})
  d = plt.plotargs
  d_out = Dict()

  bgcolor = webcolor(d[:background_color])
  fgcolor = webcolor(d[:foreground_color])

  # set the fields for the plot
  d_out[:title] = d[:title]
  d_out[:titlefont] = plotlyfont(d[:guidefont])
  d_out[:margin] = Dict(:l=>35, :b=>30, :r=>8, :t=>20)
  d_out[:plot_bgcolor] = bgcolor
  
  # TODO: x/y axis tick values/labels
  # TODO: x/y axis range

  # x-axis
  d_out[:xaxis] = Dict(
      :title      => d[:xlabel],
      :showgrid   => d[:grid],
      :zeroline   => false,
    )
  merge!(d_out[:xaxis], if use_axis_field(d[:xticks])
    Dict(
        :titlefont  => plotlyfont(d[:guidefont]),
        :type       => plotlyscale(d[:xscale]),
        :tickfont   => plotlyfont(d[:tickfont]),
        :tickcolor  => fgcolor,
        :linecolor  => fgcolor,
      )
  else
    Dict(
        :showticklabels => false,
        :showgrid       => false,
      )
  end)

  lims = d[:xlims]
  if lims != :auto && limsType(lims) == :limits
    d_out[:xaxis][:range] = lims
  end

  # y-axis
  d_out[:yaxis] = Dict(
      :title      => d[:ylabel],
      :showgrid   => d[:grid],
      :zeroline   => false,
    )
  merge!(d_out[:yaxis], if use_axis_field(d[:yticks])
    Dict(
        :titlefont  => plotlyfont(d[:guidefont]),
        :type       => plotlyscale(d[:yscale]),
        :tickfont   => plotlyfont(d[:tickfont]),
        :tickcolor  => fgcolor,
        :linecolor  => fgcolor,
      )
  else
    Dict(
        :showticklabels => false,
        :showgrid       => false,
      )
  end)

  lims = d[:ylims]
  if lims != :auto && limsType(lims) == :limits
    d_out[:yaxis][:range] = lims
  end

  # legend
  d_out[:showlegend] = d[:legend]
  if d[:legend]
    d_out[:legend] = Dict(
        :bgcolor  => bgcolor,
        :bordercolor => fgcolor,
        :font     => plotlyfont(d[:legendfont]),
      )
  end

  # annotations
  anns = get(d, :annotation_list, [])
  if !isempty(anns)
    d_out[:annotations] = [get_annotation_dict(ann...) for ann in anns]
  end

  # finally build and return the json
  JSON.json(d_out)
end


function plotly_colorscale(grad::ColorGradient)
  [[grad.values[i], webcolor(grad.colors[i])] for i in 1:length(grad.colors)]
end
plotly_colorscale(c) = plotly_colorscale(ColorGradient(:bluesreds))

const _plotly_markers = Dict(
    :rect       => "square",
    :xcross     => "x",
    :utriangle  => "triangle-up",
    :dtriangle  => "triangle-down",
    :star5      => "star-triangle-up",
    :vline      => "line-ns",
    :hline      => "line-ew",
  )

# get a dictionary representing the series params (d is the Plots-dict, d_out is the Plotly-dict)
function get_series_json(d::Dict; plot_index = nothing)
  d_out = Dict()

  x, y = collect(d[:x]), collect(d[:y])
  d_out[:name] = d[:label]

  lt = d[:linetype]
  isscatter = lt in (:scatter, :scatter3d)
  hasmarker = isscatter || d[:markershape] != :none
  hasline = !isscatter

  # set the "type"
  if lt in (:line, :path, :scatter, :steppre, :steppost)
    d_out[:type] = "scatter"
    d_out[:mode] = if hasmarker
      hasline ? "lines+markers" : "markers"
    else
      hasline ? "lines" : "none"
    end
    if d[:fillrange] == true || d[:fillrange] == 0
      d_out[:fill] = "tozeroy"
      d_out[:fillcolor] = webcolor(d[:fillcolor], d[:fillalpha])
    elseif !(d[:fillrange] in (false, nothing))
      warn("fillrange ignored... plotly only supports filling to zero. fillrange: $(d[:fillrange])")
    end
    d_out[:x], d_out[:y] = x, y

  elseif lt == :bar
    d_out[:type] = "bar"
    d_out[:x], d_out[:y] = x, y

  elseif lt == :heatmap
    d_out[:type] = "histogram2d"
    d_out[:x], d_out[:y] = x, y
    if isa(d[:nbins], Tuple)
      xbins, ybins = d[:nbins]
    else
      xbins = ybins = d[:nbins]
    end
    d_out[:nbinsx] = xbins
    d_out[:nbinsy] = ybins

  elseif lt in (:hist, :density)
    d_out[:type] = "histogram"
    isvert = d[:orientation] in (:vertical, :v, :vert)
    d_out[isvert ? :x : :y] = y
    d_out[isvert ? :nbinsx : :nbinsy] = d[:nbins]
    if lt == :density
      d_out[:histnorm] = "probability density"
    end

  elseif lt in (:contour, :surface, :wireframe)
    d_out[:type] = lt == :wireframe ? :surface : string(lt)
    d_out[:x], d_out[:y] = x, y
    d_out[:z] = d[:z].surf
    # d_out[:showscale] = d[:legend]
    if lt == :contour
      d_out[:ncontours] = d[:nlevels]
      d_out[:contours] = Dict(:coloring => d[:fillrange] != nothing ? "fill" : "lines")
    end
    d_out[:colorscale] = plotly_colorscale(d[lt == :contour ? :linecolor : :fillcolor])

  elseif lt == :pie
    d_out[:type] = "pie"
    d_out[:labels] = x
    d_out[:values] = y
    d_out[:hoverinfo] = "label+percent+name"

  elseif lt in (:path3d, :scatter3d)
    d_out[:type] = "scatter3d"
    d_out[:mode] = if hasmarker
      hasline ? "lines+markers" : "markers"
    else
      hasline ? "lines" : "none"
    end
    d_out[:x], d_out[:y] = x, y
    d_out[:z] = collect(d[:z])

  else
    error("Plotly: linetype $lt isn't supported.")
  end

  # add "marker"
  if hasmarker
    d_out[:marker] = Dict(
        :symbol => get(_plotly_markers, d[:markershape], string(d[:markershape])),
        :opacity => d[:markeralpha],
        :size => 2 * d[:markersize],
        :color => webcolor(d[:markercolor], d[:markeralpha]),
        :line => Dict(
            :color => webcolor(d[:markerstrokecolor], d[:markerstrokealpha]),
            :width => d[:markerstrokewidth],
          ),
      )
    if d[:zcolor] != nothing
      d_out[:marker][:color] = d[:zcolor]
      d_out[:marker][:colorscale] = plotly_colorscale(d[:markercolor])
    end
  end

  # add "line"
  if hasline
    d_out[:line] = Dict(
        :color => webcolor(d[:linecolor], d[:linealpha]),
        :width => d[:linewidth],
        :shape => if lt == :steppre
          "vh"
        elseif lt == :steppost
          "hv"
        else
          "linear"
        end,
        :dash => string(d[:linestyle]),
        # :dash => "solid",
      )
  end

  # # for subplots, we need to add the xaxis/yaxis fields
  # if plot_index != nothing
  #   d_out[:xaxis] = "x$(plot_index)"
  #   d_out[:yaxis] = "y$(plot_index)"
  # end

  d_out
end

# get a list of dictionaries, each representing the series params
function get_series_json(plt::Plot{PlotlyPackage})
  JSON.json(map(get_series_json, plt.seriesargs))
end

function get_series_json(subplt::Subplot{PlotlyPackage})
  ds = Dict[]
  for (i,plt) in enumerate(subplt.plts)
    for d in plt.seriesargs
      push!(ds, get_series_json(d, plot_index = i))
    end
  end
  JSON.json(ds)
end

# ----------------------------------------------------------------

function html_head(plt::PlottingObject{PlotlyPackage})
  "<script src=\"$(Pkg.dir("Plots","deps","plotly-latest.min.js"))\"></script>"
end

function html_body(plt::Plot{PlotlyPackage}, style = nothing)
  if style == nothing
    w, h = plt.plotargs[:size]
    style = "width:$(w)px;height:$(h)px;"
  end
  uuid = Base.Random.uuid4()
  """
    <div id=\"$(uuid)\" style=\"$(style)\"></div>
    <script>
      PLOT = document.getElementById('$(uuid)');
      Plotly.plot(PLOT, $(get_series_json(plt)), $(get_plot_json(plt)));
    </script>
  """
end



function html_body(subplt::Subplot{PlotlyPackage})
  w, h = subplt.plts[1].plotargs[:size]
  html = ["<div style=\"width:$(w)px;height:$(h)px;\">"]
  nr = nrows(subplt.layout)
  ph = h / nr
  
  for r in 1:nr
    push!(html, "<div style=\"clear:both;\">")
  
    nc = ncols(subplt.layout, r)
    pw = w / nc

    for c in 1:nc
      plt = subplt[r,c]
      push!(html, html_body(plt, "float:left; width:$(pw)px; height:$(ph)px;"))
    end
    
    push!(html, "</div>")
  end
  push!(html, "</div>")

  join(html)
end


# ----------------------------------------------------------------


function Base.writemime(io::IO, ::MIME"image/png", plt::PlottingObject{PlotlyPackage})
  isijulia() && return
  # TODO: write a png to io
  println("todo: png")
end

function Base.writemime(io::IO, ::MIME"text/html", plt::PlottingObject{PlotlyPackage})
  write(io, html_head(plt) * html_body(plt))
end

function Base.display(::PlotsDisplay, plt::PlottingObject{PlotlyPackage})
  standalone_html_window(plt)
end

# function Base.display(::PlotsDisplay, plt::Subplot{PlotlyPackage})
#   # TODO: display/show the subplot
# end
