package com.example.apiagrovida

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.PopupMenu
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView

class TerrenosAdapter(
    private var items: MutableList<TerrenoItem>,
    private val onClick: (TerrenoItem) -> Unit,
    private val onEdit: (TerrenoItem) -> Unit,
    private val onDelete: (TerrenoItem) -> Unit
) : RecyclerView.Adapter<TerrenosAdapter.VH>() {

    fun update(newItems: List<TerrenoItem>) {
        items.clear()
        items.addAll(newItems)
        notifyDataSetChanged()
    }

    fun getCurrentItems(): List<TerrenoItem> = items

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
        val v = LayoutInflater.from(parent.context).inflate(R.layout.item_terreno, parent, false)
        return VH(v)
    }

    override fun getItemCount() = items.size

    override fun onBindViewHolder(holder: VH, position: Int) = holder.bind(items[position])

    inner class VH(v: View) : RecyclerView.ViewHolder(v) {
        private val tvNombre = v.findViewById<TextView>(R.id.tvNombre)
        private val tvPropietario = v.findViewById<TextView>(R.id.tvPropietario)
        private val tvCoords = v.findViewById<TextView>(R.id.tvCoords)
        private val btnMore = v.findViewById<ImageView>(R.id.btnMore)

        fun bind(t: TerrenoItem) {
            tvNombre.text = t.nombre
            tvPropietario.text = if (t.propietario.isNotEmpty()) "Propietario: ${t.propietario}" else ""
            tvCoords.text = "(${String.format("%.4f", t.lat)}, ${String.format("%.4f", t.lon)})"

            itemView.setOnClickListener { onClick(t) }

            btnMore.setOnClickListener {
                val pm = PopupMenu(it.context, it)
                pm.menu.add("Editar nombre")
                pm.menu.add("Eliminar")
                pm.setOnMenuItemClickListener { mi ->
                    when (mi.title) {
                        "Editar nombre" -> onEdit(t)
                        "Eliminar" -> onDelete(t)
                    }
                    true
                }
                pm.show()
            }
        }
    }
}
