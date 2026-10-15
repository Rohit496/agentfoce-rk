import { useCallback, useEffect, useRef } from "react";
import { debounce, FILTER_DEBOUNCE_MS } from "../utils/debounce";

/**
 * Returns a stable debounced wrapper around the provided callback.
 *
 * The wrapper always invokes the *latest* version of `fn` (via a ref),
 * so the debounce timer is never reset when `fn` changes — only when
 * the caller invokes the returned function again.
 *
 * @param fn - The callback to debounce.
 * @param delay - Debounce delay in ms. Defaults to `FILTER_DEBOUNCE_MS`.
 */
export function useDebouncedCallback<A extends unknown[]>(
	fn: (...args: A) => void,
	delay: number = FILTER_DEBOUNCE_MS,
): (...args: A) => void {
	const fnRef = useRef(fn);
	const debouncedRef = useRef<((...args: A) => void) | null>(null);

	useEffect(() => {
		fnRef.current = fn;
	});

	useEffect(() => {
		debouncedRef.current = debounce((...args: A) => {
			fnRef.current(...args);
		}, delay);
	}, [delay]);

	return useCallback((...args: A) => {
		debouncedRef.current?.(...args);
	}, []);
}
