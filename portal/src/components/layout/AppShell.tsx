import { Outlet } from 'react-router-dom';
import { Header } from './Header';
import { Sidebar } from './Sidebar';

export function AppShell() {
  return (
    <div className="min-h-screen bg-bhoomi-background flex flex-col">
      <Header />
      <div className="flex flex-1">
        <Sidebar />
        <div className="flex-1 flex flex-col overflow-y-auto min-w-0">
          <Outlet />
        </div>
      </div>
    </div>
  );
}
