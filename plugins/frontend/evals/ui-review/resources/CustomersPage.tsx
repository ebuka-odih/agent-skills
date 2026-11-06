import { Trash2 } from "lucide-react";
import { useEffect, useState } from "react";

export default function CustomersPage() {
  const [rows, setRows] = useState<any[]>([]);
  useEffect(() => { fetch("/api/customers").then((r) => r.json()).then(setRows); }, []);

  return (
    <div className="p-[22px]">
      <h1 style={{ fontSize: 26, color: "#111827" }}>Customers</h1>
      <div className="mt-[18px] flex gap-[7px]">
        <button className="bg-blue-600 text-white px-3 py-2 rounded">Export</button>
        <button className="bg-indigo-500 text-white px-4 py-1.5 rounded-xl">Add customer</button>
      </div>
      <table className="mt-5 w-full">
        <tbody>
          {rows.map((c) => (
            <tr key={c.id} className="border-b border-gray-200">
              <td>{c.name}</td>
              <td className="text-right">{"₦" + c.balance / 100}</td>
              <td><button onClick={() => fetch(`/api/customers/${c.id}`, { method: "DELETE" })}><Trash2 className="text-red-500" /></button></td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
