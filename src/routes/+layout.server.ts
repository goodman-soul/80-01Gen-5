import type { LayoutServerLoad } from './$types';
import { createServerClient, type CookieOptions } from '@supabase/ssr';
import { PUBLIC_SUPABASE_ANON_KEY, PUBLIC_SUPABASE_URL } from '$env/static/public';
import { redirect } from '@sveltejs/kit';

export const load: LayoutServerLoad = async ({ cookies, url }) => {
	const allCookies = cookies.getAll();

	const supabase = createServerClient(PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, {
		cookies: {
			getAll() {
				return allCookies;
			},
			setAll(cookiesToSet: { name: string; value: string; options: CookieOptions }[]) {
				cookiesToSet.forEach(({ name, value, options }) =>
					cookies.set(name, value, { ...options, path: '/' })
				);
			}
		}
	});

	const {
		data: { session }
	} = await supabase.auth.getSession();

	const protectedRoutes = ['/parent', '/therapist', '/admin'];
	const authRoutes = ['/login', '/register'];
	const isProtected = protectedRoutes.some((r) => url.pathname.startsWith(r));
	const isAuthRoute = authRoutes.includes(url.pathname);

	if (isProtected && !session) {
		redirect(303, `/login?next=${encodeURIComponent(url.pathname)}`);
	}

	if (isAuthRoute && session) {
		let profile = null;
		const { data: profileData } = await supabase
			.from('profiles')
			.select('role')
			.eq('id', session.user.id)
			.single();
		profile = profileData;

		if (profile?.role === 'parent') redirect(303, '/parent');
		if (profile?.role === 'therapist') redirect(303, '/therapist');
		if (profile?.role === 'admin') redirect(303, '/admin');
		redirect(303, '/');
	}

	return { cookies: allCookies };
};
