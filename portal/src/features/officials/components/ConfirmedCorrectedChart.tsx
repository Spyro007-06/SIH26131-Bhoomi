import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer,
} from 'recharts';
import { Card, CardHeader, CardTitle, CardContent } from '@/components/ui/Card';
import { formatTargetLabel } from '@/lib/utils/formatters';
import type { LabelAccuracy } from '@/types/api';

interface ConfirmedCorrectedChartProps {
  rows: LabelAccuracy[];
}

export function ConfirmedCorrectedChart({ rows }: ConfirmedCorrectedChartProps) {
  if (rows.length === 0) {
    return null;
  }

  const chartData = rows.map((r) => ({
    name: formatTargetLabel(r.label),
    confirmed: r.confirmed,
    corrected: r.corrected,
  }));

  return (
    <Card className="rounded-2xl border border-bhoomi-border bg-bhoomi-surface shadow-card overflow-hidden">
      <CardHeader className="pb-3 border-b border-bhoomi-border/70 bg-bhoomi-canvas/40">
        <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-1">
          <div>
            <CardTitle className="text-base font-bold text-bhoomi-text-primary">
              Confirmed vs. Corrected Diagnoses
            </CardTitle>
            <p className="text-xs text-bhoomi-text-muted mt-0.5">
              Comparison of agronomist confirmations against corrections per disease target
            </p>
          </div>
          <div className="text-xs text-bhoomi-text-muted">
            Data source: <span className="font-mono text-bhoomi-text-primary">GET /officials/accuracy</span>
          </div>
        </div>
      </CardHeader>
      <CardContent className="pt-6">
        {/* Accessible Summary for Screen Readers */}
        <div className="sr-only">
          <h4>Visual chart summary:</h4>
          <ul>
            {rows.map((r) => (
              <li key={r.label}>
                {formatTargetLabel(r.label)}: {r.confirmed} confirmed cases, {r.corrected} corrected cases.
              </li>
            ))}
          </ul>
        </div>

        <div className="w-full h-[320px] sm:h-[380px]">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart
              data={chartData}
              margin={{ top: 20, right: 30, left: 0, bottom: 40 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#E2E8F0" vertical={false} />
              <XAxis
                dataKey="name"
                tick={{ fill: '#475569', fontSize: 11 }}
                angle={-25}
                textAnchor="end"
                interval={0}
                height={60}
              />
              <YAxis
                tick={{ fill: '#475569', fontSize: 11 }}
                allowDecimals={false}
              />
              <Tooltip
                contentStyle={{
                  backgroundColor: '#FFFFFF',
                  borderColor: '#E2E8F0',
                  borderRadius: '0.75rem',
                  fontSize: '12px',
                  boxShadow: '0 4px 12px -2px rgb(0 0 0 / 0.08)',
                }}
                formatter={(value: number, name: string) => [
                  `${value} cases`,
                  name === 'confirmed' ? 'Confirmed by Agronomist' : 'Corrected by Agronomist',
                ]}
              />
              <Legend
                verticalAlign="top"
                align="right"
                wrapperStyle={{ paddingBottom: '16px', fontSize: '12px' }}
                formatter={(value) => (
                  <span className="text-xs font-semibold text-bhoomi-text-primary">
                    {value === 'confirmed' ? 'Confirmed (Agreed)' : 'Corrected (Changed)'}
                  </span>
                )}
              />
              <Bar
                dataKey="confirmed"
                name="confirmed"
                fill="#2E7D32"
                radius={[6, 6, 0, 0]}
                maxBarSize={48}
              />
              <Bar
                dataKey="corrected"
                name="corrected"
                fill="#D97706"
                radius={[6, 6, 0, 0]}
                maxBarSize={48}
              />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </CardContent>
    </Card>
  );
}
