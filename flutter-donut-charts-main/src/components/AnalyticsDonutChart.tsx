import { useState } from "react";
import { PieChart, Pie, Cell, ResponsiveContainer, Sector } from "recharts";
import { ArrowUpRight } from "lucide-react";

const data = [
  { name: "Earned", value: 40911, color: "hsl(162, 48%, 45%)", display: "$40,911" },
  { name: "Spent", value: 12273, color: "hsl(252, 40%, 55%)", display: "$12,273" },
  { name: "Available", value: 8182, color: "hsl(68, 60%, 55%)", display: "$8,182" },
  { name: "Savings", value: 4091, color: "hsl(36, 70%, 65%)", display: "$4,091" },
];

const colorClasses = ["bg-primary", "bg-secondary", "bg-chart-available", "bg-accent"];

const renderActiveShape = (props: any) => {
  const { cx, cy, innerRadius, outerRadius, startAngle, endAngle, fill } = props;
  return (
    <g>
      <Sector
        cx={cx} cy={cy}
        innerRadius={innerRadius - 4}
        outerRadius={outerRadius + 6}
        startAngle={startAngle}
        endAngle={endAngle}
        fill={fill}
        cornerRadius={1}
      />
    </g>
  );
};

const AnalyticsDonutChart = () => {
  const [activeIndex, setActiveIndex] = useState<number | null>(null);

  const centerLabel = activeIndex !== null ? data[activeIndex].name : "Total Balance";
  const centerValue = activeIndex !== null ? data[activeIndex].display : "$8,182";

  return (
    <div className="bg-card rounded-[var(--radius)] p-6 max-w-md w-full shadow-2xl shadow-black/30">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-foreground text-xl font-semibold">Analytics</h2>
        <button className="w-10 h-10 rounded-full bg-muted flex items-center justify-center hover:bg-muted/80 transition-colors">
          <ArrowUpRight className="w-4 h-4 text-foreground" />
        </button>
      </div>

      <div className="flex items-center gap-6">
        <div className="relative w-44 h-44 flex-shrink-0">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                innerRadius={50}
                outerRadius={78}
                paddingAngle={3}
                dataKey="value"
                stroke="none"
                cornerRadius={4}
                activeIndex={activeIndex !== null ? activeIndex : undefined}
                activeShape={renderActiveShape}
                onMouseEnter={(_, index) => setActiveIndex(index)}
                onMouseLeave={() => setActiveIndex(null)}
                onClick={(_, index) => setActiveIndex(prev => prev === index ? null : index)}
              >
                {data.map((entry, index) => (
                  <Cell
                    key={index}
                    fill={entry.color}
                    opacity={activeIndex !== null && activeIndex !== index ? 0.3 : 1}
                    style={{ transition: "opacity 0.2s" }}
                    cursor="pointer"
                  />
                ))}
              </Pie>
            </PieChart>
          </ResponsiveContainer>
          <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
            <span className="text-muted-foreground text-[10px] tracking-wide transition-all">{centerLabel}</span>
            <span className="text-foreground text-xl font-bold transition-all">{centerValue}</span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-x-6 gap-y-4">
          {data.map((item, i) => (
            <div
              key={item.name}
              className="flex items-start gap-2 cursor-pointer transition-opacity duration-200"
              style={{ opacity: activeIndex !== null && activeIndex !== i ? 0.3 : 1 }}
              onMouseEnter={() => setActiveIndex(i)}
              onMouseLeave={() => setActiveIndex(null)}
              onClick={() => setActiveIndex(prev => prev === i ? null : i)}
            >
              <span className={`w-2.5 h-2.5 rounded-full mt-1.5 ${colorClasses[i]}`} />
              <div>
                <p className="text-foreground text-sm font-medium leading-tight">{item.name}</p>
                <p className="text-muted-foreground text-xs">{item.display}</p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
};

export default AnalyticsDonutChart;
